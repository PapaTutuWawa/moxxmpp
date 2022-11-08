import 'package:moxxmpp_socket/src/record.dart';

/// Sorts the SRV records according to priority and weight.
int srvRecordSortComparator(MoxSrvRecord a, MoxSrvRecord b) {
  if (a.priority < b.priority) {
    return -1;
  } else {
    if (a.priority > b.priority) {
      return 1;
    }

    // a.priority == b.priority
    if (a.weight < b.weight) {
      return -1;
    } else if (a.weight > b.weight) {
      return 1;
    } else {
      return 0;
    }
  }
}
