// RFC 6120
const saslXmlns = 'urn:ietf:params:xml:ns:xmpp-sasl';
const stanzaXmlns = 'jabber:client';
const streamXmlns = 'http://etherx.jabber.org/streams';
const bindXmlns = 'urn:ietf:params:xml:ns:xmpp-bind';
const startTlsXmlns = 'urn:ietf:params:xml:ns:xmpp-tls';
const fullStanzaXmlns = 'urn:ietf:params:xml:ns:xmpp-stanzas';

// RFC 6121
const rosterXmlns = 'jabber:iq:roster';
const rosterVersioningXmlns = 'urn:xmpp:features:rosterver';
const subscriptionPreApprovalXmlns = 'urn:xmpp:features:pre-approval';

// XEP-0004
const dataFormsXmlns = 'jabber:x:data';
const formVarFormType = 'FORM_TYPE';

// XEP-0030
const discoInfoXmlns = 'http://jabber.org/protocol/disco#info';
const discoItemsXmlns = 'http://jabber.org/protocol/disco#items';

// XEP-0033
const extendedAddressingXmlns = 'http://jabber.org/protocol/address';

// XEP-0045
const mucXmlns = 'http://jabber.org/protocol/muc';
const mucUserXmlns = 'http://jabber.org/protocol/muc#user';
const roomInfoFormType = 'http://jabber.org/protocol/muc#roominfo';

// XEP-0054
const vCardTempXmlns = 'vcard-temp';
const vCardTempUpdate = 'vcard-temp:x:update';

// XEP-0060
const pubsubXmlns = 'http://jabber.org/protocol/pubsub';
const pubsubEventXmlns = 'http://jabber.org/protocol/pubsub#event';
const pubsubOwnerXmlns = 'http://jabber.org/protocol/pubsub#owner';
const pubsubPublishOptionsXmlns =
    'http://jabber.org/protocol/pubsub#publish-options';
const pubsubNodeConfigMax = 'http://jabber.org/protocol/pubsub#config-node-max';
const pubsubNodeConfigMultiItems =
    'http://jabber.org/protocol/pubsub#multi-items';

// XEP-0066
const oobDataXmlns = 'jabber:x:oob';

// XEP-0084
const userAvatarDataXmlns = 'urn:xmpp:avatar:data';
const userAvatarMetadataXmlns = 'urn:xmpp:avatar:metadata';

// XEP-0085
const chatStateXmlns = 'http://jabber.org/protocol/chatstates';

// XEP-0114
const componentAcceptXmlns = 'jabber:component:accept';

// XEP-0115
const capsXmlns = 'http://jabber.org/protocol/caps';

// XEP-0184
const deliveryXmlns = 'urn:xmpp:receipts';

// XEP-0191
const blockingXmlns = 'urn:xmpp:blocking';

// XEP-0198
const smXmlns = 'urn:xmpp:sm:3';

// XEP-0203
const delayedDeliveryXmlns = 'urn:xmpp:delay';

// XEP-0234
const jingleFileTransferXmlns = 'urn:xmpp:jingle:apps:file-transfer:5';

// XEP-0264
const jingleContentThumbnailXmlns = 'urn:xmpp:thumbs:1';

// XEP-0280
const carbonsXmlns = 'urn:xmpp:carbons:2';

// XEP-0297
const forwardedXmlns = 'urn:xmpp:forward:0';

// XEP-0300
const hashXmlns = 'urn:xmpp:hashes:2';
const hashFunctionNameBaseXmlns = 'urn:xmpp:hash-function-text-names';

// XEP-0308
const lmcXmlns = 'urn:xmpp:message-correct:0';

// XEP-0333
const chatMarkersXmlns = 'urn:xmpp:chat-markers:0';

// XEP-0334
const messageProcessingHintsXmlns = 'urn:xmpp:hints';

// XEP-0352
const csiXmlns = 'urn:xmpp:csi:0';

// XEP-0359
const stableIdXmlns = 'urn:xmpp:sid:0';

// XEP-0363
const httpFileUploadXmlns = 'urn:xmpp:http:upload:0';

// XEP-0372
const referenceXmlns = 'urn:xmpp:reference:0';

// XEP-0380
const emeXmlns = 'urn:xmpp:eme:0';
const emeOtr = 'urn:xmpp:otr:0';
const emeLegacyOpenPGP = 'jabber:x:encrypted';
const emeOpenPGP = 'urn:xmpp:openpgp:0';
const emeOmemo = 'eu.siacs.conversations.axolotl';
const emeOmemo1 = 'urn:xmpp:omemo:1';
const emeOmemo2 = 'urn:xmpp:omemo:2';

// XEP-0384
const omemoXmlns = 'urn:xmpp:omemo:2';
const omemoDevicesXmlns = 'urn:xmpp:omemo:2:devices';
const omemoBundlesXmlns = 'urn:xmpp:omemo:2:bundles';

// XEP-0385
const simsXmlns = 'urn:xmpp:sims:1';

// XEP-0386
const bind2Xmlns = 'urn:xmpp:bind:0';

// XEP-0388
const sasl2Xmlns = 'urn:xmpp:sasl:2';

// XEP-0420
const sceXmlns = 'urn:xmpp:sce:1';

// XEP-0421
const occupantIdXmlns = 'urn:xmpp:occupant-id:0';

// XEP-0422
const fasteningXmlns = 'urn:xmpp:fasten:0';

// XEP-0424
const messageRetractionXmlns = 'urn:xmpp:message-retract:0';

// XEP-0428
const fallbackIndicationXmlns = 'urn:xmpp:fallback:0';

// XEP-0444
const messageReactionsXmlns = 'urn:xmpp:reactions:0';

// XEP-0446
const fileMetadataXmlns = 'urn:xmpp:file:metadata:0';

// XEP-0447
const sfsXmlns = 'urn:xmpp:sfs:0';

// XEP-0448
const sfsEncryptionXmlns = 'urn:xmpp:esfs:0';
const sfsEncryptionAes128GcmNoPaddingXmlns =
    'urn:xmpp:ciphers:aes-128-gcm-nopadding:0';
const sfsEncryptionAes256GcmNoPaddingXmlns =
    'urn:xmpp:ciphers:aes-256-gcm-nopadding:0';
const sfsEncryptionAes256CbcPkcs7Xmlns = 'urn:xmpp:ciphers:aes-256-cbc-pkcs7:0';

// XEP-0449
const stickersXmlns = 'urn:xmpp:stickers:0';

// XEP-0461
const replyXmlns = 'urn:xmpp:reply:0';

// ???
const urlDataXmlns = 'http://jabber.org/protocol/url-data';

// XEP-XXXX
const fastXmlns = 'urn:xmpp:fast:0';
