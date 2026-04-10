import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../domain/usecases/get_playlists_usecase.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  static const _tag = 'LibraryCubit';

  final GetPlaylistsUseCase _getPlaylists;

  LibraryCubit({required GetPlaylistsUseCase getPlaylists})
      : _getPlaylists = getPlaylists,
        super(const LibraryState(isLoading: true, playlists: [])) {
    AppLogger.i(_tag, 'Created');
    _load();
  }

  Future<void> reload() {
    AppLogger.i(_tag, 'reload()');
    emit(const LibraryState(isLoading: true, playlists: []));
    return _load();
  }

  Future<void> _load() async {
    try {
      AppLogger.d(_tag, 'Fetching playlists...');
      final playlists = await _getPlaylists();
      if (isClosed) return;
      AppLogger.i(_tag, 'Loaded ${playlists.length} playlists');
      emit(LibraryState(isLoading: false, playlists: playlists));
    } on AuthException {
      if (isClosed) return;
      AppLogger.w(_tag, '401 — library requires authentication');
      emit(const LibraryState(
        isLoading: false,
        error: true,
        errorType: AppErrorType.unauthenticated,
        playlists: [],
      ));
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Load failed: ${e.message}');
      emit(LibraryState(
        isLoading: false,
        error: true,
        errorType: e.errorType,
        playlists: [],
      ));
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      emit(const LibraryState(
        isLoading: false,
        error: true,
        errorType: AppErrorType.unknown,
        playlists: [],
      ));
    }
  }

  void setFilter(int index) {
    if (state.filterIndex == index) return;
    emit(state.copyWith(filterIndex: index));
  }
}
