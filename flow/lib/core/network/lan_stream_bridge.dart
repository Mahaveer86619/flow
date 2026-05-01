import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/sources/stream_resolver.dart';
import '../logger/app_logger.dart';
import '../../domain/entities/device_peer.dart';

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
      AppLogger.i(_tag, 'LAN Stream Server started on port $port');

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

          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
        } catch (e) {
          AppLogger.e(_tag, 'Error handling LAN stream request', e);
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      });
    } catch (e) {
      AppLogger.e(_tag, 'Failed to start LAN Stream Server', e);
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    AppLogger.i(_tag, 'LAN Stream Server stopped');
  }

  // Desktop side — requests a stream from paired mobile
  String getProxyUrl(String videoId, DevicePeer mobile) {
    if (mobile.lastKnownIp == null) return '';
    return 'http://${mobile.lastKnownIp}:$port/stream/$videoId';
  }
}
