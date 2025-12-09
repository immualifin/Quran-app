import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/globals.dart';
import 'package:quran_app/models/ayat.dart';
import 'package:quran_app/models/surah.dart';
import 'package:quran_app/services/bookmark_storage.dart';
import 'package:quran_app/services/last_read_storage.dart';

class DetailScreen extends StatefulWidget {
  final int noSurat;
  const DetailScreen({super.key, required this.noSurat});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Future<Surah> _getDetailSurah() async {
    var response = await Dio().get(
      'https://equran.id/api/v2/surat/${widget.noSurat}',
    );
    final surah = surahDetailFromJson(response.toString());

    // Save last read
    LastReadStorage().saveLastRead(
      surahName: surah.namaLatin,
      surahNumber: surah.nomor,
      ayatNumber: 1, // Defaulting to Ayat 1 on open
    );

    return surah;
  }

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Surah>(
      future: _getDetailSurah(),
      initialData: null,
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: background,
            body: Center(child: CircularProgressIndicator(color: cardColor)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: background,
            body: Center(
              child: Text(
                'Gagal memuat detail surah.\nPeriksa koneksi internet Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }

        Surah surah = snapshot.data!;

        // Filter logic
        List<Ayat>? displayedAyat = surah.ayat;
        if (_isSearching && _searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          displayedAyat = surah.ayat?.where((ayat) {
            final translation = ayat.idn.toLowerCase();
            final number = ayat.nomor.toString();
            return translation.contains(query) || number.contains(query);
          }).toList();
        }

        return Scaffold(
          backgroundColor: background,
          appBar: _appBar(context: context, surah: surah),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _details(surah: surah)),
            ],
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: displayedAyat == null || displayedAyat.isEmpty
                  ? Center(
                      child: Text(
                        "Tidak ada ayat yang ditemukan",
                        style: GoogleFonts.poppins(),
                      ),
                    )
                  : ListView.separated(
                      itemBuilder: (context, index) {
                        // If we are searching, we use the filtered list directly, preserving the 'nomor' from the ayat object
                        // If not searching, we use the original logic if needed, but the ayat object has the correct number.
                        final Ayat ayat = displayedAyat![index];
                        return AyatItem(ayat: ayat, surah: surah);
                      },
                      itemCount: displayedAyat?.length ?? 0,
                      separatorBuilder: (context, index) => Container(),
                    ),
            ),
          ),
        );
      }),
    );
  }

  AppBar _appBar({required BuildContext context, required Surah surah}) =>
      AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: (() => Navigator.of(context).pop()),
              icon: SvgPicture.asset('assets/svgs/back-icon.svg'),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari ayat...',
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    )
                  : Text(
                      surah.namaLatin,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
              icon: _isSearching
                  ? const Icon(Icons.close, color: Colors.grey)
                  : SvgPicture.asset('assets/svgs/search-icon.svg'),
            ),
          ],
        ),
      );
}

class AyatItem extends StatefulWidget {
  final Ayat ayat;
  final Surah surah;

  const AyatItem({super.key, required this.ayat, required this.surah});

  @override
  State<AyatItem> createState() => _AyatItemState();
}

class _AyatItemState extends State<AyatItem> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final bookmarkStorage = BookmarkStorage();
      final List<String> bookmarks = await bookmarkStorage.getBookmarks();
      final String bookmarkKey = '${widget.surah.nomor}:${widget.ayat.nomor}';

      bool isFound = false;
      for (String bookmark in bookmarks) {
        try {
          final decoded = jsonDecode(bookmark) as Map<String, dynamic>;
          if (decoded['key']?.toString() == bookmarkKey) {
            isFound = true;
            break;
          }
        } catch (e) {
          print('Error parsing bookmark in _loadBookmarkStatus: $e');
          continue;
        }
      }

      setState(() {
        _isBookmarked = isFound;
      });

      print('Bookmark status for $bookmarkKey: $_isBookmarked');
    } catch (e) {
      print('Error loading bookmark status: $e');
      setState(() {
        _isBookmarked = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      print('=== TOGGLE BOOKMARK START ===');
      final bookmarkStorage = BookmarkStorage();
      final List<String> bookmarks = await bookmarkStorage.getBookmarks();
      final String bookmarkKey = '${widget.surah.nomor}:${widget.ayat.nomor}';

      print('Current bookmarks count: ${bookmarks.length}');
      print('Bookmark key: $bookmarkKey');
      print('Current status: $_isBookmarked');

      final bookmarkData = {
        'key': bookmarkKey,
        'surah_name': widget.surah.namaLatin,
        'surah_number': widget.surah.nomor,
        'ayat_number': widget.ayat.nomor,
        'ayat_text_ar': widget.ayat.ar,
        'ayat_text_idn': widget.ayat.idn,
      };

      bool wasBookmarked = _isBookmarked;
      List<String> updatedBookmarks = List.from(bookmarks);

      if (wasBookmarked) {
        // Remove bookmark
        print('Removing bookmark...');
        int originalLength = updatedBookmarks.length;
        updatedBookmarks.removeWhere((b) {
          try {
            final decoded = jsonDecode(b) as Map<String, dynamic>;
            bool matches = decoded['key']?.toString() == bookmarkKey;
            if (matches)
              print('Found and removed bookmark: ${decoded['surah_name']}');
            return matches;
          } catch (e) {
            print('Error parsing bookmark for removal: $e');
            return false;
          }
        });
        int removedCount = originalLength - updatedBookmarks.length;
        print('Removed $removedCount bookmarks');
      } else {
        // Add bookmark
        print('Adding bookmark...');
        String bookmarkJson = jsonEncode(bookmarkData);
        updatedBookmarks.add(bookmarkJson);
        print(
          'Added bookmark: ${bookmarkData['surah_name']} ayat ${bookmarkData['ayat_number']}',
        );
      }

      // Save using BookmarkStorage
      bool saveSuccess = await bookmarkStorage.saveBookmarks(updatedBookmarks);
      print('Save success: $saveSuccess');

      if (saveSuccess) {
        print('New bookmarks count: ${updatedBookmarks.length}');

        // Update state
        setState(() {
          _isBookmarked = !wasBookmarked;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked
                  ? '✓ Ditambahkan ke bookmark'
                  : '✓ Dihapus dari bookmark',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _isBookmarked ? Colors.green : Colors.orange,
          ),
        );

        print('Bookmark ${_isBookmarked ? "added" : "removed"} successfully');
      } else {
        throw Exception('Failed to save bookmarks');
      }
      print('=== TOGGLE BOOKMARK END ===');
    } catch (e) {
      print('!!! ERROR toggling bookmark: $e');
      print('Stack trace: ${StackTrace.current}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah bookmark: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Retry after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                _toggleBookmark();
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(27 / 2),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.ayat.nomor}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    print(
                      'Bookmark button tapped! Current status: $_isBookmarked',
                    );
                    _toggleBookmark();
                  },
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isBookmarked ? Colors.blue.shade700 : cardColor,
                    size: 24,
                  ),
                  tooltip: _isBookmarked
                      ? 'Hapus dari bookmark'
                      : 'Tambah ke bookmark',
                ),
                IconButton(
                  onPressed: () {
                    LastReadStorage().saveLastRead(
                      surahName: widget.surah.namaLatin,
                      surahNumber: widget.surah.nomor,
                      ayatNumber: widget.ayat.nomor,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ditandai sebagai terakhir dibaca',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: cardColor,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.flag_outlined, color: cardColor),
                  tooltip: 'Tandai Terakhir Dibaca',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.ayat.ar,
            style: GoogleFonts.amiri(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            widget.ayat.tr,
            style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          Text(
            widget.ayat.idn,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Widget _details({required Surah surah}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: Stack(
    children: [
      Container(
        height: 257,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, .6, 1],
            colors: [Color(0xFFDF98FA), Color(0xFFB070FD), Color(0xFF9055FF)],
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Opacity(
          opacity: .2,
          child: SvgPicture.asset('assets/svgs/quran.svg', width: 324 - 55),
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(
              surah.namaLatin,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              surah.arti,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(.35),
              thickness: 2,
              height: 32,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  surah.tempatTurun.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "${surah.jumlahAyat} Ayat",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (surah.nomor != 9) SvgPicture.asset('assets/svgs/bismillah.svg'),
          ],
        ),
      ),
    ],
  ),
);
