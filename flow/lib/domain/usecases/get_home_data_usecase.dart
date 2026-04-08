import '../entities/home_data.dart';
import '../repositories/song_repository.dart';

/// Returns structured home screen data from the repository.
///
/// This replaces the old pattern of fetching a flat song list and manually
/// splitting it into sections inside the Cubit. The backend now owns that
/// logic; the Cubit just loads and emits.
class GetHomeDataUseCase {
  final SongRepository _repository;
  const GetHomeDataUseCase(this._repository);
  Future<HomeData> call() => _repository.getHomeData();
}
