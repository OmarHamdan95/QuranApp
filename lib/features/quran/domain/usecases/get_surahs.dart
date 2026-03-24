import 'package:dartz/dartz.dart';
import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

/// Use case: fetch all surahs of the Quran.
///
/// Returns a sorted list of all 114 surahs, or a [QuranFailure].
class GetSurahs {
  final QuranRepository _repository;

  const GetSurahs(this._repository);

  Future<Either<QuranFailure, List<Surah>>> call() {
    return _repository.getSurahs();
  }
}
