abstract class RosterError {}

/// Returned when the server's response did not contain a <query /> element
class NoQueryError extends RosterError {}

/// Unspecified error
class UnknownError extends RosterError {}
