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

/// This error occurs when a user attempts to perform an action that requires
/// them to be a member of a room, but they are not currently joined to
/// that room.
class RoomNotJoinedError extends MUCError {}

/// Indicates that the MUC forbids us from joining, i.e. when we're banned.
class JoinForbiddenError extends MUCError {}

/// Indicates that an unspecific error occurred while joining.
class MUCUnspecificError extends MUCError {}
