import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/globals.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/services/bookmark_storage.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  Future<List<Map<String, dynamic>>>? _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _bookmarksFuture = _getBookmarks();
    });
    // Wait for a moment to ensure the state is updated
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<List<Map<String, dynamic>>> _getBookmarks() async {
    try {
      final bookmarkStorage = BookmarkStorage();
      final List<String> bookmarksJson = await bookmarkStorage.getBookmarks();

      if (bookmarksJson.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> validBookmarks = [];

      for (String jsonString in bookmarksJson) {
        try {
          final Map<String, dynamic> bookmark = jsonDecode(jsonString) as Map<String, dynamic>;

          // Validate that required fields exist and are not null/empty
          if (bookmark.containsKey('surah_name') &&
              bookmark.containsKey('ayat_number') &&
              bookmark.containsKey('ayat_text_ar') &&
              bookmark.containsKey('key') &&
              bookmark['surah_name'] != null &&
              bookmark['ayat_number'] != null &&
              bookmark['ayat_text_ar'] != null &&
              bookmark['key'] != null &&
              bookmark['surah_name'].toString().isNotEmpty &&
              bookmark['ayat_text_ar'].toString().isNotEmpty) {

            validBookmarks.add(bookmark);
          } else {
            print('Invalid bookmark data: missing required fields');
          }
        } catch (e) {
          // Skip invalid bookmark entries
          print('Invalid bookmark entry: $e');
          continue;
        }
      }

      return validBookmarks.reversed.toList(); // Show latest bookmarks first
    } catch (e) {
      print('Error loading bookmarks: $e');
      return [];
    }
  }

  Future<void> _deleteBookmark(String bookmarkKey) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus Bookmark', style: GoogleFonts.poppins()),
          content: Text('Apakah Anda yakin ingin menghapus bookmark ini?',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final bookmarkStorage = BookmarkStorage();
        final List<String> bookmarks = await bookmarkStorage.getBookmarks();

        bookmarks.removeWhere((bookmark) {
          try {
            final decoded = jsonDecode(bookmark) as Map<String, dynamic>;
            return decoded['key']?.toString() == bookmarkKey;
          } catch (e) {
            print('Error parsing bookmark for deletion: $e');
            return false;
          }
        });

        bool success = await bookmarkStorage.saveBookmarks(bookmarks);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bookmark berhasil dihapus', style: GoogleFonts.poppins()),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to save bookmarks');
        }

        _loadBookmarks();
      }
    } catch (e) {
      print('Error deleting bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus bookmark', style: GoogleFonts.poppins()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(context),
      body: RefreshIndicator(
        onRefresh: _loadBookmarks,
        color: cardColor,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: cardColor));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat bookmark',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadBookmarks,
                      child: Text(
                        'Coba Lagi',
                        style: GoogleFonts.poppins(color: cardColor),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/svgs/bookmark-icon.svg', width: 100, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada bookmark',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan bookmark dari halaman detail surah',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final bookmarks = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: bookmarks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return _bookmarkItem(context, bookmark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _bookmarkItem(BuildContext context, Map<String, dynamic> bookmark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DetailScreen(noSurat: bookmark['surah_number']),
                    ));
                    // Refresh the list when returning from detail screen
                    _loadBookmarks();
                  },
                  child: Text(
                    '${bookmark['surah_name']} : Ayat ${bookmark['ayat_number']}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: cardColor,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _deleteBookmark(bookmark['key']),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                tooltip: 'Hapus bookmark',
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DetailScreen(noSurat: bookmark['surah_number']),
              ));
              // Refresh the list when returning from detail screen
              _loadBookmarks();
            },
            child: Text(
              bookmark['ayat_text_ar'],
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
        backgroundColor: background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: (() {
                Navigator.pop(context);
              }),
              icon: SvgPicture.asset('assets/svgs/back-icon.svg'),
            ),
            const SizedBox(width: 24),
            Text(
              'Bookmarks',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: titleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}