/// A data class to represent a DNS SRV record.
class MoxSrvRecord {
  MoxSrvRecord(this.priority, this.weight, this.target, this.port);
  final int priority;
  final int weight;
  final int port;
  final String target;
}
