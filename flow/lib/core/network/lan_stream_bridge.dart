import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/sources/remote/stream_resolver.dart';
import '../logger/app_logger.dart';
import '../../domain/entities/device_peer.dart';
import '../intelligence/app_intelligence.dart';
import 'mdns_service.dart';
import '../storage/local_storage.dart';

class LanStreamBridge {
  LanStreamBridge._();
  static final LanStreamBridge instance = LanStreamBridge._();

  HttpServer? _server;
  final Dio _dio = Dio();
  static const _tag = 'LanStreamBridge';
  static const int port = 7788;

  // Mobile side — listens for stream requests from paired desktop
  Future<void> startServer() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      AppLogger.i(_tag, 'LAN Server started on port $port');

      final deviceId = LocalStorage.instance.recentlyPlayedIds.isNotEmpty 
          ? 'flow-${LocalStorage.instance.recentlyPlayedIds.first.hashCode}'
          : 'flow-device';
          
      MDnsService.instance.startAdvertising(deviceId, port);

      _server!.listen((HttpRequest request) async {
        try {
          if (request.uri.path.startsWith('/stream/')) {
            final videoId = request.uri.pathSegments.last;
            AppLogger.d(_tag, 'Received LAN stream request for $videoId');
            
            final streamUrl = await StreamResolver.instance.resolveYoutubeStream(videoId);
            if (streamUrl == null) {
              request.response.statusCode = HttpStatus.notFound;
              await request.response.close();
              return;
            }

            // Proxy the bytes from YT → peer
            final ytResponse = await _dio.get<ResponseBody>(
              streamUrl,
              options: Options(responseType: ResponseType.stream),
            );

            request.response.statusCode = ytResponse.statusCode ?? HttpStatus.ok;
            // Forward headers
            ytResponse.headers.forEach((name, values) {
              request.response.headers.set(name, values);
            });

            await request.response.addStream(ytResponse.data!.stream);
            await request.response.close();
          } else if (request.uri.path.startsWith('/sync/')) {
            if (request.method == 'GET') {
              // Peer is requesting our delta
              final peerId = request.uri.queryParameters['peerId'] ?? 'unknown';
              final delta = await AppIntelligence.instance.getDeltaForPeer(peerId);
              request.response.statusCode = HttpStatus.ok;
              request.response.headers.contentType = ContentType.json;
              request.response.write(jsonEncode(delta.toJson()));
              await request.response.close();
            } else if (request.method == 'POST') {
              // Peer is sending us their delta
              final body = await utf8.decoder.bind(request).join();
              final data = jsonDecode(body);
              final map = data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
              await AppIntelligence.instance.applyDeltaFromJson(map);
              request.response.statusCode = HttpStatus.accepted;
              await request.response.close();
            }

          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
        } catch (e) {
          AppLogger.e(_tag, 'Error handling LAN request', e);
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      });
    } catch (e) {
      AppLogger.e(_tag, 'Failed to start LAN Server', e);
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    AppLogger.i(_tag, 'LAN Server stopped');
  }

  // Desktop side — requests a stream from paired mobile
  String getProxyUrl(String videoId, DevicePeer mobile) {
    if (mobile.lastKnownIp == null) return '';
    return 'http://${mobile.lastKnownIp}:$port/stream/$videoId';
  }

  // Desktop side — triggers a sync with mobile
  Future<void> triggerPeerSync(DevicePeer mobile) async {
    if (mobile.lastKnownIp == null) return;
    try {
      final response = await _dio.get(
        'http://${mobile.lastKnownIp}:$port/sync/',
        queryParameters: {'peerId': 'local-device-id'},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final map = data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
        await AppIntelligence.instance.applyDeltaFromJson(map);
        AppLogger.i(_tag, 'Peer sync complete');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Peer sync failed', e);
    }
  }
}
