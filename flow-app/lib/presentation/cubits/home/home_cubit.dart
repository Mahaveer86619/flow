import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../data/models/home_data_model.dart'; // for .toEntity()
import '../../../data/sources/song_data_source.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
import 'home_state.dart';

export 'home_state.dart';

// ── HomeCubit ─────────────────────────────────────────────────────────────────
//
// Loads home screen data via [GetHomeDataUseCase] — one network call.
//
// Auth-aware: if the server returns 401 (or the cached auth state is false),
// the cubit falls back to [SongDataSource.fetchFeed()] which returns trending /
// chart data without requiring authentication.  The state carries [isAuthenticated]
// so the UI can show a "sign in for personalised music" banner.
// ─────────────────────────────────────────────────────────────────────────────

class HomeCubit extends Cubit<HomeState> {
  static const _tag = 'HomeCubit';

  final GetHomeDataUseCase _getHomeData;
  final SongDataSource _dataSource;

  HomeCubit({
    required GetHomeDataUseCase getHomeData,
    required SongDataSource dataSource,
  })  : _getHomeData = getHomeData,
        _dataSource = dataSource,
        super(const HomeState(isLoading: true)) {
    AppLogger.i(_tag, 'Created');
    _load();
  }

  Future<void> reload() {
    AppLogger.i(_tag, 'reload()');
    emit(const HomeState(isLoading: true));
    return _load();
  }

  Future<void> _load() async {
    // If we already know the server is unauthenticated, skip straight to feed.
    if (!LocalStorage.instance.isAuthenticated) {
      return _loadFeed();
    }

    try {
      AppLogger.d(_tag, 'Fetching home data (authenticated)...');
      final HomeData data = await _getHomeData();
      if (isClosed) return;
      _emitLoaded(data, isAuthenticated: true);
    } on AuthException {
      AppLogger.w(_tag, '401 from home — falling back to feed');
      LocalStorage.instance.saveIsAuthenticated(false);
      return _loadFeed();
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Load failed: ${e.message}');
      emit(HomeState(isLoading: false, error: true, errorType: e.errorType));
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      emit(const HomeState(
        isLoading: false,
        error: true,
        errorType: AppErrorType.unknown,
      ));
    }
  }

  Future<void> _loadFeed() async {
    try {
      AppLogger.d(_tag, 'Fetching feed (unauthenticated)...');
      final HomeDataModel model = await _dataSource.fetchFeed();
      if (isClosed) return;
      _emitLoaded(model.toEntity(), isAuthenticated: false);
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Feed load failed: ${e.message}');
      emit(HomeState(isLoading: false, error: true, errorType: e.errorType));
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Feed unexpected error', e, st);
      emit(const HomeState(
        isLoading: false,
        error: true,
        errorType: AppErrorType.unknown,
      ));
    }
  }

  void _emitLoaded(HomeData data, {required bool isAuthenticated}) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    AppLogger.i(_tag,
        'Loaded — auth=$isAuthenticated allSongs=${data.allSongs.length}');

    emit(HomeState(
      isLoading: false,
      greeting: greeting,
      quickAccess: data.quickAccess,
      listeningAgain: data.listeningAgain,
      forgottenFavorites: data.forgottenFavorites,
      musicForYou: data.musicForYou,
      trendingArtists: data.trendingArtists,
      trending: data.trending,
      allSongs: data.allSongs,
      isAuthenticated: isAuthenticated,
    ));
  }
}
