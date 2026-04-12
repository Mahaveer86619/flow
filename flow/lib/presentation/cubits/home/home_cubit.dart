import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/usecases/get_home_data_usecase.dart';
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

  HomeCubit({required GetHomeDataUseCase getHomeData})
    : _getHomeData = getHomeData,
      super(const HomeState(isLoading: true)) {
    AppLogger.i(_tag, 'Created');
    _load();
  }

  Future<void> reload() {
    AppLogger.i(_tag, 'reload()');
    emit(state.copyWith(isLoading: true, error: false, noSource: false));
    return _load();
  }

  /// Pull-to-refresh: keep existing data, just reload in background.
  Future<void> refresh() {
    AppLogger.i(_tag, 'refresh()');
    return _load();
  }

  Future<void> _load() async {
    // If the user has no YT auth, show the no-source view immediately.
    if (!LocalStorage.instance.cachedHasYtAuth) {
      AppLogger.i(_tag, 'No YT auth — emitting noSource');
      if (!isClosed) emit(const HomeState(noSource: true));
      return;
    }

    try {
      AppLogger.d(_tag, 'Fetching home data...');
      final data = await _getHomeData();
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

      emit(
        HomeState(
          isLoading: false,
          greeting: greeting,
          shelves: data.shelves,
          trending: data.trending,
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
