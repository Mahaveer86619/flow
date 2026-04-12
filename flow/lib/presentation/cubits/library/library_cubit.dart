import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/download_service.dart';
import '../../../domain/repositories/song_repository.dart';
import '../../../domain/usecases/get_playlists_usecase.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  static const _tag = 'LibraryCubit';

  final GetPlaylistsUseCase _getPlaylists;
  final SongRepository _songRepository;

  LibraryCubit({
    required GetPlaylistsUseCase getPlaylists,
    required SongRepository songRepository,
  }) : _getPlaylists = getPlaylists,
       _songRepository = songRepository,
       super(const LibraryState(isLoading: true, playlists: [])) {
    AppLogger.i(_tag, 'Created');
    _load();
  }

  Future<void> reload() {
    AppLogger.i(_tag, 'reload()');
    emit(state.copyWith(isLoading: true));
    if (state.filterIndex == 3) {
      return _loadDownloads();
    }
    return _load();
  }

  Future<void> _load() async {
    try {
      AppLogger.d(_tag, 'Fetching playlists...');
      final playlists = await _getPlaylists();
      if (isClosed) return;
      AppLogger.i(_tag, 'Loaded ${playlists.length} playlists');
      emit(state.copyWith(isLoading: false, playlists: playlists));
    } on AppException catch (e) {
      if (isClosed) return;
      AppLogger.w(_tag, 'Load failed: ${e.message}');
      emit(
        state.copyWith(isLoading: false, error: true, errorType: e.errorType),
      );
    } catch (e, st) {
      if (isClosed) return;
      AppLogger.e(_tag, 'Unexpected error', e, st);
      emit(
        state.copyWith(
          isLoading: false,
          error: true,
          errorType: AppErrorType.unknown,
        ),
      );
    }
  }

  Future<void> _loadDownloads() async {
    try {
      emit(state.copyWith(isLoading: true));
      final ids = DownloadService.instance.getDownloadedIds();
      if (ids.isEmpty) {
        emit(state.copyWith(isLoading: false, downloadedSongs: []));
        return;
      }
      final songs = await _songRepository.getSongsByIds(ids);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, downloadedSongs: songs));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: true));
    }
  }

  void setFilter(int index) {
    if (state.filterIndex == index) return;
    emit(state.copyWith(filterIndex: index));
    if (index == 3) {
      _loadDownloads();
    }
  }
}
