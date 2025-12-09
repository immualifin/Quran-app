import 'package:shared_preferences/shared_preferences.dart';

class LastReadStorage {
  static const String keyLastReadSurah = 'last_read_surah';
  static const String keyLastReadSurahNumber = 'last_read_surah_number';
  static const String keyLastReadAyatNumber = 'last_read_ayat_number';

  Future<void> saveLastRead({
    required String surahName,
    required int surahNumber,
    required int ayatNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLastReadSurah, surahName);
    await prefs.setInt(keyLastReadSurahNumber, surahNumber);
    await prefs.setInt(keyLastReadAyatNumber, ayatNumber);
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surahName = prefs.getString(keyLastReadSurah);
    final surahNumber = prefs.getInt(keyLastReadSurahNumber);
    final ayatNumber = prefs.getInt(keyLastReadAyatNumber);

    if (surahName != null && surahNumber != null && ayatNumber != null) {
      return {
        'surahName': surahName,
        'surahNumber': surahNumber,
        'ayatNumber': ayatNumber,
      };
    }
    return null;
  }
}
