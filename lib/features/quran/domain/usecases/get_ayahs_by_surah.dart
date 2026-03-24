import 'package:dartz/dartz.dart';
import '../entities/ayah.dart';
import '../repositories/quran_repository.dart';

/// Use case: fetch all ayahs for a specific surah.
///
/// Takes a surah number (1-114) and returns the list of ayahs in order.
class GetAyahsBySurah {
  final QuranRepository _repository;

  const GetAyahsBySurah(this._repository);

  Future<Either<QuranFailure, List<Ayah>>> call(int surahNumber) {
    assert(surahNumber >= 1 && surahNumber <= 114);
    return _repository.getAyahsBySurah(surahNumber);
  }
}
