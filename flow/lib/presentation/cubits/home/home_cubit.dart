import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_event_bus.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/history_data.dart';
import '../../../domain/repositories/song_repository.dart';
import 'home_state.dart';

export 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const _tag = 'HomeCubit';

  final GetHomeDataUseCase _getHomeData;
  final SongRepository _songRepository;
  StreamSubscription? _eventSub;

  HomeCubit({
    required GetHomeDataUseCase getHomeData,
    required SongRepository songRepository,
  }) : _getHomeData = getHomeData,
       _songRepository = songRepository,
       super(const HomeState(isLoading: true)) {
    AppLogger.i(_tag, 'Created');

    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is GlobalRetryEvent) {
        if (state.error || state.noSource) {
          reload(isGlobal: true);
        }
      }
    });

    _load();
  }

  Future<void> reload({bool isGlobal = false}) {
    AppLogger.i(_tag, 'reload(isGlobal: $isGlobal)');
    if (!isGlobal) {
      AppEventBus.instance.fire(GlobalRetryEvent());
    }
    emit(state.copyWith(isLoading: true, error: false, noSource: false));
    return _load();
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }

  Future<void> refresh() {
    AppLogger.i(_tag, 'refresh()');
    return _load();
  }

  Future<void> _load() async {
    // ── STANDALONE SOURCE CHECK (Phase 2) ──────────────────────────────────
    // Check local secure storage for cookies.
    final ytCookies = await SecureStorageService.instance.getYoutubeCookies();
    final hasYtLocal = ytCookies != null && ytCookies.isNotEmpty;

    if (!hasYtLocal) {
      AppLogger.i(_tag, 'No local YT cookies found — emitting noSource');
      if (!isClosed) emit(const HomeState(noSource: true));
      return;
    }

    try {
      AppLogger.d(_tag, 'Fetching home data and history (Standalone)...');
      final dataFuture = _getHomeData(limit: 48);
      final historyFuture = _songRepository.getPersistentHistory();

      final results = await Future.wait([dataFuture, historyFuture]);
      final data = results[0] as HomeData;
      final history = results[1] as HistoryData;

      if (isClosed) return;

      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning'
          : hour < 17
          ? 'Good afternoon'
          : 'Good evening';

      AppLogger.i(
        _tag,
        'Loaded — allSongs=${data.allSongs.length}  greeting=$greeting',
      );

      final recent = [
        ...history.today,
        ...history.thisWeek,
        ...history.thisMonth,
      ].take(12).toList();

      emit(
        HomeState(
          isLoading: false,
          greeting: greeting,
          shelves: data.shelves,
          trending: data.trending,
          recentlyPlayed: recent,
          allSongs: data.allSongs,
          profileUrl: data.profileUrl,
          ytName: data.ytName,
          musicVideos: data.musicVideos,
          favArtistsSongs: data.favArtistsSongs,
        ),
      );
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Load failed: ${e.message}');
      emit(HomeState(isLoading: false, error: true, errorType: e.errorType));
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      emit(
        const HomeState(
          isLoading: false,
          error: true,
          errorType: AppErrorType.unknown,
        ),
      );
    }
  }
}
