class StreamManagementData {
  const StreamManagementData(this.exclude);

  /// Whether the stanza should be exluded from the StreamManagement's resend queue.
  final bool exclude;
}
