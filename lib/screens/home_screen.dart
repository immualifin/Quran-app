import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/globals.dart';
import 'package:quran_app/tabs/surah_tab.dart';
import 'package:quran_app/tabs/doa_tab.dart';
import 'package:quran_app/screens/bookmark_screen.dart';
import 'package:quran_app/services/last_read_storage.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1; // Default to Quran tab
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _lastReadData;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // 2 tabs: Doa and Surah
    // Ensure bottom navigation shows Quran tab as active on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = 1; // Quran tab
          _tabController.animateTo(1); // Move to SurahTab
        });
      }
    });

    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      _loadLastRead(); // Reload last read when switching back to home/quran tab
    } else if (_currentIndex != _tabController.index) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      _loadLastRead();
    }
  }

  Future<void> _loadLastRead() async {
    final data = await LastReadStorage().getLastRead();
    if (mounted) {
      setState(() {
        _lastReadData = data;
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex)
      return; // Don't do anything if same tab is tapped

    // Update UI state immediately to show visual feedback
    setState(() {
      _currentIndex = index;
    });

    // Clear search when changing tabs via bottom bar
    if (index != 1 && _isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }

    // Handle navigation after UI update
    if (index == 0) {
      // Navigate to Doa tab
      _tabController.animateTo(0); // Move to DoaTab
    } else if (index == 1) {
      // Navigate to Quran tab
      _tabController.animateTo(1); // Move to SurahTab
    } else if (index == 2) {
      // Navigate to Bookmark screen when bookmark tab is tapped
      Future.delayed(const Duration(milliseconds: 100), () async {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookmarkScreen()),
          );
          if (mounted) {
            setState(() {
              _currentIndex = _tabController.index;
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _appBar(),
      bottomNavigationBar: _bottomNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _greeting()),
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: background,
              automaticallyImplyLeading: false,
              shape: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(.1),
                  width: 3,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: TabBar(
                  controller: _tabController,
                  labelColor: cardColor,
                  indicatorColor: cardColor,
                  indicatorWeight: 3,
                  indicatorPadding: const EdgeInsets.only(
                    left: -24,
                    right: -24,
                  ),
                  tabs: [
                    Tab(
                      child: Text(
                        'Doa',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Quran',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  isScrollable: false,
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              const DoaTab(),
              SurahTab(
                searchQuery: _isSearching ? _searchController.text : null,
                onReturn: _loadLastRead,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: background,
    automaticallyImplyLeading: false,
    elevation: 0,
    title: Row(
      children: [
        const SizedBox(width: 24),
        Expanded(
          child: _isSearching && _currentIndex == 1
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari surah...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
              : Text(
                  'Quran App',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (_currentIndex == 1) // Only show search icon on Quran tab
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
          )
        else
          const Spacer(),
      ],
    ),
  );

  Column _greeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamualaikum',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Muhammad Ibnu Mualifin',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        _lastRead(),
      ],
    );
  }

  Stack _lastRead() {
    return Stack(
      children: [
        Container(
          height: 131,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
          child: SvgPicture.asset('assets/svgs/quran.svg'),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/svgs/book.svg'),
                  const SizedBox(width: 8),
                  Text(
                    'Last Read',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_lastReadData != null) ...[
                Text(
                  _lastReadData!['surahName'] ?? 'Al-Fatihah',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ayat No: ${_lastReadData!['ayatNumber'] ?? 1}',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ] else ...[
                Text(
                  'Belum ada yang dibaca',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (_lastReadData != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailScreen(noSurat: _lastReadData!['surahNumber']),
                    ),
                  );
                  _loadLastRead(); // Refresh on return
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _bottomNavigationBar() => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    currentIndex: _currentIndex,
    onTap: _onTabTapped,
    items: [
      _bottomBarItem(icon: "assets/svgs/doa-icon.svg", label: "Doa"),
      _bottomBarItem(icon: "assets/svgs/quran-icon.svg", label: "Quran"),
      _bottomBarItem(icon: "assets/svgs/bookmark-icon.svg", label: "Bookmark"),
    ],
  );

  BottomNavigationBarItem _bottomBarItem({
    required String icon,
    required String label,
  }) => BottomNavigationBarItem(
    icon: SvgPicture.asset(icon, color: Colors.grey),
    activeIcon: SvgPicture.asset(icon, color: titleColor),
    label: label,
  );
}
