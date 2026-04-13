import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_event_bus.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
import '../../../domain/entities/home_data.dart';
import '../../../domain/entities/history_data.dart';
import '../../../domain/repositories/song_repository.dart';
import 'home_state.dart';

export 'home_state.dart';

// ── HomeCubit ─────────────────────────────────────────────────────────────────
//
// Loads home screen data via [GetHomeDataUseCase] — one network call.
// Section splitting is the backend's responsibility; this cubit just loads
// and emits. The greeting is the only thing computed here (client-side clock).
// ─────────────────────────────────────────────────────────────────────────────

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

  /// Pull-to-refresh: keep existing data, just reload in background.
  Future<void> refresh() {
    AppLogger.i(_tag, 'refresh()');
    return _load();
  }

  Future<void> _load() async {
    // If the user has no YT auth, show the no-source view immediately.
    final token = LocalStorage.instance.jwtToken;
    final hasYt = LocalStorage.instance.cachedHasYtAuth;

    if (token == null || !hasYt) {
      AppLogger.i(_tag, 'Unauthenticated or no YT auth — emitting noSource');
      if (!isClosed) emit(const HomeState(noSource: true));
      return;
    }

    try {
      AppLogger.d(_tag, 'Fetching home data and history...');
      final dataFuture = _getHomeData();
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

      // Combine today, this week, and this month for a "Recent" list on home
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
