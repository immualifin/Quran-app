import 'package:dio/dio.dart';
import 'package:quran_app/models/doa.dart';

class DoaService {
  static final DoaService _instance = DoaService._internal();
  factory DoaService() => _instance;
  DoaService._internal();

  final Dio _dio = Dio();

  // API doa dari doa-doa-api-ahmadramadhan.fly.dev
  // API ini menyediakan koleksi doa harian lengkap
  Future<List<Doa>> getAllDoa() async {
    try {
      final response = await _dio.get('https://doa-doa-api-ahmadramadhan.fly.dev/api');

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> data = response.data;
        return data.map((json) => Doa.fromJson(json)).toList();
      } else {
        // Fallback ke data lokal jika API gagal
        return _getLocalDoa();
      }
    } catch (e) {
      print('Error fetching doa from API: $e');
      // Return fallback data
      return _getLocalDoa();
    }
  }

  // Local fallback data untuk doa-doa umum
  List<Doa> _getLocalDoa() {
    return [
      Doa(
        id: '1',
        doa: 'Doa Sebelum Tidur',
        ayat: 'بِسْمِكَ اَللّٰهُمَّ اَحْيَا وَبِاسْمِكَ اَمُوْتُ',
        latin: 'Bismikallahumma ahyaa wa ammuut',
        artinya: 'Dengan menyebut nama Allah, aku hidup dan aku mati.',
      ),
      Doa(
        id: '2',
        doa: 'Doa Bangun Tidur',
        ayat: 'اَلْحَمْدُ لِلّٰهِ الَّذِيْ اَحْيَانَا بَعْدَمَا اَمَاتَنَا وَاِلَيْهِ النُّشُوْرُ',
        latin: 'Alhamdu lillahil ladzii ahyaanaa ba ada maa amaa tanaa wa ilahin nusyuuru',
        artinya: 'Segala puji bagi Allah yang telah menghidupkan kami sesudah kami mati dan hanya kepada-Nya kami dikembalikan.',
      ),
      Doa(
        id: '3',
        doa: 'Doa Sebelum Makan',
        ayat: 'اَللّٰهُمَّ بَارِكْ لَنَا فِيْمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
        latin: 'Allahumma baarik lanaa fiimaa rozaqtanaa wa qinaa adzaa bannaar',
        artinya: 'Ya Allah, berkahilah kami dalam rezeki yang telah Engkau berikan kepada kami dan peliharalah kami dari siksa api neraka.',
      ),
      Doa(
        id: '4',
        doa: 'Doa Sesudah Makan',
        ayat: 'اَلْحَمْدُ لِلّٰهِ الَّذِيْ اَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِيْنَ',
        latin: 'Alhamdulillahilladzi ath amanaa wa saqoonaa wa ja alanaa minal muslimiin',
        artinya: 'Segala puji bagi Allah yang telah memberi kami makan dan minum serta menjadikan kami termasuk dari kaum muslimin.',
      ),
      Doa(
        id: '5',
        doa: 'Doa Masuk Masjid',
        ayat: 'اَللّٰهُمَّ افْتَحْ لِيْ اَبْوَابَ رَحْمَتِكَ',
        latin: 'Allahummaftah lii abwaaba rohmatik',
        artinya: 'Ya Allah, bukakanlah pintu-pintu rahmatMu untukku.',
      ),
    ];
  }

  // Search doa berdasarkan judul atau artinya
  List<Doa> searchDoa(List<Doa> allDoa, String query) {
    if (query.isEmpty) return allDoa;

    String lowercaseQuery = query.toLowerCase();
    return allDoa.where((doa) {
      return doa.doa.toLowerCase().contains(lowercaseQuery) ||
             doa.artinya.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}