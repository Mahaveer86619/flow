import 'package:multicast_dns/multicast_dns.dart';
import '../logger/app_logger.dart';

class MDnsService {
  MDnsService._();
  static final MDnsService instance = MDnsService._();

  static const _tag = 'MDnsService';
  static const _serviceType = '_flow._tcp.local';
  
  Future<void> startAdvertising(String deviceId, int port) async {

    // In a real production implementation, we would use a native plugin
    // like 'bonsoir' for reliable background advertising.
    // For now, we'll log that we're ready for lookup.
    AppLogger.i(_tag, 'mDNS service $deviceId ready on port $port');
  }

  Future<List<Map<String, dynamic>>> findPeers() async {
    final List<Map<String, dynamic>> peers = [];
    final client = MDnsClient();
    await client.start();

    try {
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(_serviceType))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            peers.add({
              'name': srv.target,
              'ip': ip.address.address,
              'port': srv.port,
            });
            AppLogger.d(_tag, 'Found peer: ${srv.target} at ${ip.address.address}');
          }
        }
      }
    } catch (e) {
      AppLogger.e(_tag, 'Lookup failed', e);
    } finally {
      client.stop();
    }
    
    return peers;
  }
}
