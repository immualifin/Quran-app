import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/globals.dart';
import 'package:quran_app/models/surah.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';

class SurahTab extends StatefulWidget {
  final String? searchQuery;
  final VoidCallback? onReturn;
  const SurahTab({super.key, this.searchQuery, this.onReturn});

  @override
  State<SurahTab> createState() => _SurahTabState();
}

class _SurahTabState extends State<SurahTab> {
  late Future<List<Surah>> _surahListFuture;

  @override
  void initState() {
    super.initState();
    _surahListFuture = _getSurahList();
  }

  Future<List<Surah>> _getSurahList() async {
    var response = await Dio().get('https://equran.id/api/v2/surat');
    final List<dynamic> surahData = response.data['data'];
    return surahData.map((json) => Surah.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: _surahListFuture,
      initialData: null,
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cardColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat data.\nPeriksa koneksi internet Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada data yang tersedia.',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        // Filter functionality
        List<Surah> displayedSurahs = snapshot.data!;
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          final query = widget.searchQuery!.toLowerCase();
          displayedSurahs = displayedSurahs.where((surah) {
            return surah.namaLatin.toLowerCase().contains(query) ||
                surah.arti.toLowerCase().contains(query);
          }).toList();
        }

        return ListView.separated(
          itemBuilder: (context, index) => _surahItem(
            context: context,
            surah: displayedSurahs.elementAt(index),
          ),
          separatorBuilder: (context, index) =>
              Divider(color: const Color(0xFF7B80AD).withOpacity(.35)),
          itemCount: displayedSurahs.length,
        );
      }),
    );
  }

  Widget _surahItem({required Surah surah, required BuildContext context}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailScreen(noSurat: surah.nomor),
            ),
          );
          widget.onReturn?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Stack(
                children: [
                  SvgPicture.asset('assets/svgs/nomor-surah.svg'),
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: Center(
                      child: Text(
                        "${surah.nomor}",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.namaLatin,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          surah.tempatTurun.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: subtext,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${surah.jumlahAyat} Ayat",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                surah.nama,
                style: GoogleFonts.amiri(
                  color: cardColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
}
