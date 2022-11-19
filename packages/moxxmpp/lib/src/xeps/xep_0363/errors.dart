abstract class HttpFileUploadError {}

/// Returned when we don't know what JID to ask for an upload slot
class NoEntityKnownError extends HttpFileUploadError {}

/// Returned when the file we want to upload is too big
class FileTooBigError extends HttpFileUploadError {}

/// Unspecified errors
class UnknownHttpFileUploadError extends HttpFileUploadError {}
