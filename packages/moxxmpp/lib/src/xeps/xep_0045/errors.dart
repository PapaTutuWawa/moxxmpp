/// Represents an error related to Multi-User Chat (MUC).
abstract class MUCError {}

/// Error indicating an invalid (non-supported) stanza received while going
/// through normal operation/flow of an MUC.
class InvalidStanzaFormat extends MUCError {}

/// Represents an error indicating an abnormal condition while parsing
/// the DiscoInfo response stanza in Multi-User Chat (MUC).
class InvalidDiscoInfoResponse extends MUCError {}

/// Returned when no nickname was specified from the client side while trying to
/// perform some actions on the MUC, such as joining the room.
class NoNicknameSpecified extends MUCError {}
