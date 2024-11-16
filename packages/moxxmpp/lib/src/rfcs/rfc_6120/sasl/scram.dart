import 'dart:convert';
import 'dart:math' show Random;
import 'package:cryptography/cryptography.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/src/events.dart';
import 'package:moxxmpp/src/namespaces.dart';
import 'package:moxxmpp/src/negotiators/namespaces.dart';
import 'package:moxxmpp/src/negotiators/negotiator.dart';
import 'package:moxxmpp/src/rfcs/rfc_6120/sasl/errors.dart';
import 'package:moxxmpp/src/rfcs/rfc_6120/sasl/kv.dart';
import 'package:moxxmpp/src/rfcs/rfc_6120/sasl/nonza.dart';
import 'package:moxxmpp/src/stringxml.dart';
import 'package:moxxmpp/src/xeps/xep_0388/negotiators.dart';
import 'package:moxxmpp/src/xeps/xep_0388/xep_0388.dart';
import 'package:random_string/random_string.dart';
import 'package:saslprep/saslprep.dart';

abstract class SaslScramError extends NegotiatorError {}

class NoAdditionalDataError extends SaslScramError {
  @override
  bool isRecoverable() => false;
}

class InvalidServerSignatureError extends SaslScramError {
  @override
  bool isRecoverable() => false;
}

// NOTE: Inspired by https://github.com/vukoye/xmpp_dart/blob/3b1a0588562b9e591488c99d834088391840911d/lib/src/features/sasl/ScramSaslHandler.dart

enum ScramHashType { sha1, sha256, sha512 }

HashAlgorithm hashFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1:
      return Sha1();
    case ScramHashType.sha256:
      return Sha256();
    case ScramHashType.sha512:
      return Sha512();
  }
}

int pbkdfBitsFromHash(ScramHashType type) {
  switch (type) {
    // NOTE: SHA1 is 20 octets long => 20 octets * 8 bits/octet
    case ScramHashType.sha1:
      return 160;
    // NOTE: SHA256 is 32 octets long => 32 octets * 8 bits/octet
    case ScramHashType.sha256:
      return 256;
    // NOTE: SHA512 is 64 octets long => 64 octets * 8 bits/octet
    case ScramHashType.sha512:
      return 512;
  }
}

const scramSha1Mechanism = 'SCRAM-SHA-1';
const scramSha256Mechanism = 'SCRAM-SHA-256';
const scramSha512Mechanism = 'SCRAM-SHA-512';

String mechanismNameFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1:
      return scramSha1Mechanism;
    case ScramHashType.sha256:
      return scramSha256Mechanism;
    case ScramHashType.sha512:
      return scramSha512Mechanism;
  }
}

String namespaceFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1:
      return saslScramSha1Negotiator;
    case ScramHashType.sha256:
      return saslScramSha256Negotiator;
    case ScramHashType.sha512:
      return saslScramSha512Negotiator;
  }
}

class SaslScramAuthNonza extends SaslAuthNonza {
  // This subclassing makes less sense here, but this is since the auth nonza here
  // requires knowledge of the inner state of the Negotiator.
  SaslScramAuthNonza({required ScramHashType type, required String body})
      : super(
          mechanismNameFromType(type),
          body,
        );
}

class SaslScramResponseNonza extends XMLNode {
  SaslScramResponseNonza({required String body})
      : super(
          tag: 'response',
          attributes: <String, String>{
            'xmlns': saslXmlns,
          },
          text: body,
        );
}

enum ScramState { preSent, initialMessageSent, challengeResponseSent, error }

const gs2Header = 'n,,';

class SaslScramNegotiator extends Sasl2AuthenticationNegotiator {
  // NOTE: NEVER, and I mean, NEVER set clientNonce or initalMessageNoGS2. They are just there for testing
  SaslScramNegotiator(
    int priority,
    this.initialMessageNoGS2,
    this.clientNonce,
    this.hashType,
  )   : _hash = hashFromType(hashType),
        _serverSignature = '',
        _scramState = ScramState.preSent,
        _log =
            Logger('SaslScramNegotiator(${mechanismNameFromType(hashType)})'),
        super(
          priority,
          namespaceFromType(hashType),
          mechanismNameFromType(hashType),
        );
  String? clientNonce;
  String initialMessageNoGS2;
  final ScramHashType hashType;
  final HashAlgorithm _hash;
  String _serverSignature;

  // The internal state for performing the negotiation
  ScramState _scramState;

  final Logger _log;

  Future<List<int>> calculateSaltedPassword(String salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(_hash),
      iterations: iterations,
      bits: pbkdfBitsFromHash(hashType),
    );

    final saltedPasswordRaw = await pbkdf2.deriveKey(
      secretKey: SecretKey(
        utf8.encode(
          Saslprep.saslprep(attributes.getConnectionSettings().password),
        ),
      ),
      nonce: base64.decode(salt),
    );
    return saltedPasswordRaw.extractBytes();
  }

  Future<List<int>> calculateClientKey(List<int> saltedPassword) async {
    return (await Hmac(_hash).calculateMac(
      utf8.encode('Client Key'),
      secretKey: SecretKey(saltedPassword),
    ))
        .bytes;
  }

  Future<List<int>> calculateClientSignature(
    String authMessage,
    List<int> storedKey,
  ) async {
    return (await Hmac(_hash).calculateMac(
      utf8.encode(authMessage),
      secretKey: SecretKey(storedKey),
    ))
        .bytes;
  }

  Future<List<int>> calculateServerKey(List<int> saltedPassword) async {
    return (await Hmac(_hash).calculateMac(
      utf8.encode('Server Key'),
      secretKey: SecretKey(saltedPassword),
    ))
        .bytes;
  }

  Future<List<int>> calculateServerSignature(
    String authMessage,
    List<int> serverKey,
  ) async {
    return (await Hmac(_hash).calculateMac(
      utf8.encode(authMessage),
      secretKey: SecretKey(serverKey),
    ))
        .bytes;
  }

  List<int> calculateClientProof(
    List<int> clientKey,
    List<int> clientSignature,
  ) {
    final clientProof = List<int>.filled(clientKey.length, 0);
    for (var i = 0; i < clientKey.length; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }

    return clientProof;
  }

  Future<String> calculateChallengeResponse(String base64Challenge) async {
    final challengeString = utf8.decode(base64.decode(base64Challenge));
    final challenge = parseKeyValue(challengeString);
    final clientFinalMessageBare = 'c=biws,r=${challenge['r']!}';

    final saltedPassword = await calculateSaltedPassword(
      challenge['s']!,
      int.parse(challenge['i']!),
    );
    final clientKey = await calculateClientKey(saltedPassword);
    final storedKey = (await _hash.hash(clientKey)).bytes;
    final authMessage =
        '$initialMessageNoGS2,$challengeString,$clientFinalMessageBare';
    final clientSignature =
        await calculateClientSignature(authMessage, storedKey);
    final clientProof = calculateClientProof(clientKey, clientSignature);
    final serverKey = await calculateServerKey(saltedPassword);
    _serverSignature =
        base64.encode(await calculateServerSignature(authMessage, serverKey));

    return '$clientFinalMessageBare,p=${base64.encode(clientProof)}';
  }

  @override
  bool matchesFeature(List<XMLNode> features) {
    if (super.matchesFeature(features)) {
      if (!attributes.getSocket().isSecure()) {
        _log.warning(
          'Refusing to match SASL feature due to unsecured connection',
        );
        return false;
      }

      return true;
    }

    return false;
  }

  bool _checkSignature(String base64Signature) {
    final signature =
        parseKeyValue(utf8.decode(base64.decode(base64Signature)));
    _log.finest(
      'Expecting signature: "$_serverSignature", got: "${signature["v"]}"',
    );
    return signature['v']! == _serverSignature;
  }

  @override
  Future<Result<NegotiatorState, NegotiatorError>> negotiate(
    XMLNode nonza,
  ) async {
    switch (_scramState) {
      case ScramState.preSent:
        attributes.sendNonza(
          SaslScramAuthNonza(
            body: await getRawStep(''),
            type: hashType,
          ),
        );
        return const Result(NegotiatorState.ready);
      case ScramState.initialMessageSent:
        if (nonza.tag != 'challenge') {
          final error = nonza.children.first.tag;
          await attributes.sendEvent(AuthenticationFailedEvent(error));

          _scramState = ScramState.error;
          return Result(
            SaslError.fromFailure(nonza),
          );
        }

        attributes.sendNonza(
          SaslScramResponseNonza(body: await getRawStep(nonza.innerText())),
        );
        return const Result(NegotiatorState.ready);
      case ScramState.challengeResponseSent:
        if (nonza.tag != 'success') {
          // We assume it's a <failure />
          final error = nonza.children.first.tag;
          await attributes.sendEvent(AuthenticationFailedEvent(error));
          _scramState = ScramState.error;
          return Result(
            SaslError.fromFailure(nonza),
          );
        }

        if (!_checkSignature(nonza.innerText())) {
          // TODO(Unknown): Notify of a signature mismatch
          //final error = nonza.children.first.tag;
          //attributes.sendEvent(AuthenticationFailedEvent(error));
          _scramState = ScramState.error;
          return Result(
            SaslError.fromFailure(nonza),
          );
        }

        attributes.setAuthenticated();
        return const Result(NegotiatorState.done);
      case ScramState.error:
        return Result(
          SaslError.fromFailure(nonza),
        );
    }
  }

  @override
  void reset() {
    _scramState = ScramState.preSent;

    super.reset();
  }

  @override
  Future<String> getRawStep(String input) async {
    switch (_scramState) {
      case ScramState.preSent:
        if (clientNonce == null || clientNonce == '') {
          clientNonce = randomAlphaNumeric(
            40,
            provider: CoreRandomProvider.from(Random.secure()),
          );
        }

        initialMessageNoGS2 =
            'n=${attributes.getConnectionSettings().jid.local},r=$clientNonce';

        _scramState = ScramState.initialMessageSent;
        return base64.encode(utf8.encode(gs2Header + initialMessageNoGS2));
      case ScramState.initialMessageSent:
        final challengeBase64 = input;
        final response = await calculateChallengeResponse(challengeBase64);
        final responseBase64 = base64.encode(utf8.encode(response));
        _scramState = ScramState.challengeResponseSent;

        return responseBase64;
      case ScramState.challengeResponseSent:
      case ScramState.error:
        return '';
    }
  }

  @override
  Future<void> postRegisterCallback() async {
    attributes
        .getNegotiatorById<Sasl2Negotiator>(sasl2Negotiator)
        ?.registerSaslNegotiator(this);
  }

  @override
  Future<List<XMLNode>> onSasl2FeaturesReceived(XMLNode sasl2Features) async {
    return [];
  }

  @override
  Future<void> onSasl2Failure(XMLNode response) async {}

  @override
  Future<Result<bool, NegotiatorError>> onSasl2Success(XMLNode response) async {
    // Don't do anything if we have not been picked for SASL2.
    if (!pickedForSasl2) {
      return const Result(true);
    }

    // When we're done with SASL2, check the additional data to verify the server
    // signature.
    state = NegotiatorState.done;
    final additionalData = response.firstTag('additional-data');
    if (additionalData == null) {
      return Result(NoAdditionalDataError());
    }

    if (!_checkSignature(additionalData.innerText())) {
      return Result(InvalidServerSignatureError());
    }

    return const Result(true);
  }
}
