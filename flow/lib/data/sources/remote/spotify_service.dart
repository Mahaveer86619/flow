import 'package:spotify/spotify.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/logger/app_logger.dart';

class SpotifyService {
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  SpotifyApi? _spotify;
  static const _tag = 'SpotifyService';

  Future<void> init() async {
    final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
    final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'];

    if (clientId == null || clientSecret == null) {
      AppLogger.w(_tag, 'Spotify credentials missing in .env');
      return;
    }

    try {
      final credentials = SpotifyApiCredentials(clientId, clientSecret);
      _spotify = SpotifyApi(credentials);
      AppLogger.i(_tag, 'Spotify initialized (Client Credentials)');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to initialize Spotify', e);
    }
  }

  SpotifyApi? get api => _spotify;
}
