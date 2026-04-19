import '../repositories/music_repository.dart';

/// Returns the browse category list (name + color pairs).
class GetCategoriesUseCase {
  final MusicRepository _repository;

  const GetCategoriesUseCase(this._repository);

  List<Map<String, dynamic>> call() => _repository.getCategories();
}
