import 'package:args/args.dart';
import 'package:chalkdart/chalk.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

extension StringToInt on String {
  int toInt() => int.parse(this);
}

/// A wrapper around [ArgParser] for providing convenience functions and standard parameters
/// to the examples.
class ArgumentParser {
  ArgumentParser() {
    parser
      ..addOption('jid', help: 'The JID to connect as')
      ..addOption('password', help: 'The password to use for authenticating')
      ..addOption('host',
          help:
              'The host address to connect to (By default uses the domain part of the JID)')
      ..addOption('port', help: 'The port to connect to')
      ..addOption('xmpps-srv',
          help:
              'Inject a SRV record for _xmpps-client._tcp. Format: <priority>,<weight>,<target>,<port>')
      ..addFlag('help',
          abbr: 'h',
          negatable: false,
          defaultsTo: false,
          help: 'Show this help text');
  }

  /// The [ArgParser] that handles parsing the arguments.
  final ArgParser parser = ArgParser();

  /// The parsed options. Only valid after calling [handleArguments].
  late ArgResults options;

  ArgResults? handleArguments(List<String> args) {
    options = parser.parse(args);
    if (options['help']!) {
      print(parser.usage);
      return null;
    }

    if (options['jid'] == null) {
      print(chalk.red('No JID specified'));
      print(parser.usage);
      return null;
    }

    if (options['password'] == null) {
      print(chalk.red('No password specified'));
      print(parser.usage);
      return null;
    }

    return options;
  }

  /// The JID to connect as.
  JID get jid => JID.fromString(options['jid']!).toBare();

  /// Construct connection settings from the parsed options.
  ConnectionSettings get connectionSettings => ConnectionSettings(
        jid: jid,
        password: options['password']!,
        host: options['host'],
        port: (options['port'] as String?)?.toInt(),
      );

  /// Construct an xmpps-client SRV record for injection, if specified.
  MoxSrvRecord? get srvRecord {
    if (options['xmpps-srv'] == null) {
      return null;
    }

    final parts = options['xmpps-srv']!.split(',');
    return MoxSrvRecord(
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts[2],
      int.parse(parts[3]),
    );
  }
}
