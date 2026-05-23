import 'package:flutter/material.dart';
import 'booking_page.dart';
import 'psikolog_profile_sheet.dart'; // Import sudah diperbaiki!

// ─── Sanctuary Design Tokens ────────────────────────────────────────────────
const _kPrimary      = Color(0xFF5C6BC0);
const _kPrimaryLight = Color(0xFFE8EAF6);
const _kAccent       = Color(0xFF26A69A);
const _kBg           = Color(0xFFF0F2F8);
const _kCardBg       = Color(0xFFFFFFFF);
const _kTextPrimary  = Color(0xFF1C1F33);
const _kTextSub      = Color(0xFF6B7280);

class JadwalPage extends StatefulWidget {
  final List<dynamic> jadwalList;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onBookingSuccess;

  const JadwalPage({
    super.key,
    required this.jadwalList,
    required this.isLoading,
    required this.onRefresh,
    required this.onBookingSuccess,
  });

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  String _searchQuery = '';
  String _selectedDay = 'Semua';

  String _getNamaHari(String dateStr) {
    try {
      if (dateStr.length >= 10) {
        DateTime dt = DateTime.parse(dateStr.substring(0, 10));
        List<String> hari = [
          '',
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu'
        ];
        return hari[dt.weekday];
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  List<String> get _availableDays {
    List<String> days = ['Semua'];
    for (var jadwal in widget.jadwalList) {
      String hari = _getNamaHari(jadwal['tanggal'] ?? '');
      if (hari.isNotEmpty && !days.contains(hari)) {
        days.add(hari);
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    // Filter Pencarian Teks dan Hari
    final filteredList = widget.jadwalList.where((jadwal) {
      final nama = (jadwal['nama_lengkap'] ?? '').toString().toLowerCase();
      final spesialisasi =
          (jadwal['spesialisasi'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final cocokQuery =
          nama.contains(query) || spesialisasi.contains(query);

      if (_selectedDay == 'Semua') {
        return cocokQuery;
      } else {
        return cocokQuery &&
            _getNamaHari(jadwal['tanggal'] ?? '') == _selectedDay;
      }
    }).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _kCardBg,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F5C6BC0),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: _kTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jadwal Psikolog',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _kTextPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Pilih sesi konseling tersedia',
                              style: TextStyle(
                                  fontSize: 12, color: _kTextSub),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchAndFilterSection(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── List Content ───────────────────────────────────────────
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary))
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: widget.onRefresh,
                        color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final jadwal = filteredList[index];
                            String hari =
                                _getNamaHari(jadwal['tanggal'] ?? '');
                            String tgl = jadwal['tanggal'] != null
                                ? jadwal['tanggal'].toString().substring(0, 10)
                                : '';

                            return _JadwalCard(
                              jadwal: jadwal,
                              hari: hari,
                              tgl: tgl,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingPage(
                                      jadwalData: jadwal,
                                      onBookingSuccess:
                                          widget.onBookingSuccess,
                                    ),
                                  ),
                                );
                              },
                              onAvatarTap: () {
                                PsikologProfileSheet.show(context,
                                    Map<String, dynamic>.from(jadwal));
                              },
                              onNameTap: () {
                                PsikologProfileSheet.show(context,
                                    Map<String, dynamic>.from(jadwal));
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded,
                size: 40, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada jadwal tersedia',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ganti filter atau kata kunci pencarianmu',
            style: TextStyle(color: _kTextSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        // Search Field
        Container(
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E3F0), width: 1),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(
                color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Cari psikolog atau spesialisasi...',
              hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: _kPrimary, size: 20),
              filled: false,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Day Filter Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _availableDays.map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (isSelected) return;
                    setState(() => _selectedDay = day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _kPrimary
                            : const Color(0xFFE0E3F0),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _kTextSub,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Jadwal Card Widget ──────────────────────────────────────────────────────
class _JadwalCard extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  final String hari;
  final String tgl;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onNameTap;

  const _JadwalCard({
    required this.jadwal,
    required this.hari,
    required this.tgl,
    required this.onTap,
    required this.onAvatarTap,
    required this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Clickable Avatar
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7986CB), _kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable Name
                      GestureDetector(
                        onTap: onNameTap,
                        child: Text(
                          jadwal['nama_lengkap'] ?? 'Nama Psikolog',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _kPrimary,
                            decoration: TextDecoration.underline,
                            decorationColor: _kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Spesialisasi badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          jadwal['spesialisasi'] ?? 'Umum',
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Date & time
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded,
                              size: 13, color: _kAccent),
                          const SizedBox(width: 5),
                          Text(
                            '$hari, $tgl  •  ${jadwal['jam_mulai']?.substring(0, 5)} WIB',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kTextSub,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 15, color: _kPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}