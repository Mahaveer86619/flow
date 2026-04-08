import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_playlists_usecase.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({required GetPlaylistsUseCase getPlaylists})
      : super(LibraryState(playlists: getPlaylists()));

  void setFilter(int index) {
    if (state.filterIndex == index) return;
    emit(state.copyWith(filterIndex: index));
  }
}
