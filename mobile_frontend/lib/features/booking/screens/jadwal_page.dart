import 'package:flutter/material.dart';
import 'booking_page.dart';
import 'psikolog_profile_sheet.dart'; // Import sudah diperbaiki!

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
        List<String> hari = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
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
      final spesialisasi = (jadwal['spesialisasi'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final cocokQuery = nama.contains(query) || spesialisasi.contains(query);

      if (_selectedDay == 'Semua') {
        return cocokQuery;
      } else {
        return cocokQuery && _getNamaHari(jadwal['tanggal'] ?? '') == _selectedDay;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchAndFilterSection(),
                ),
                
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text('Tidak ada jadwal konseling berstatus tersedia.'))
                      : RefreshIndicator(
                          onRefresh: widget.onRefresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final jadwal = filteredList[index];
                              String hari = _getNamaHari(jadwal['tanggal'] ?? '');
                              String tgl = jadwal['tanggal'] != null 
                                  ? jadwal['tanggal'].substring(0, 10) 
                                  : '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // Masuk ke detail jadwal (Booking Page)
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingPage(
                                          jadwalData: jadwal,
                                          onBookingSuccess: widget.onBookingSuccess,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Foto Profil Bisa Diklik -> Buka Pop Up Profil
                                        GestureDetector(
                                          onTap: () {
                                            PsikologProfileSheet.show(context, Map<String, dynamic>.from(jadwal));
                                          },
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                                            child: const Icon(Icons.person_rounded, color: Color(0xFF007AFF)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Nama Psikolog Bisa Diklik -> Buka Pop Up Profil
                                              InkWell(
                                                onTap: () {
                                                  PsikologProfileSheet.show(context, Map<String, dynamic>.from(jadwal));
                                                },
                                                child: Text(
                                                  jadwal['nama_lengkap'] ?? 'Nama Psikolog',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF007AFF), // Warna Biru Bisa Diklik
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                jadwal['spesialisasi'] ?? 'Umum',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '$hari, $tgl • ${jadwal['jam_mulai']?.substring(0, 5)} WIB',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Cari psikolog atau spesialisasi...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 35,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _availableDays.map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDay = day);
                  },
                  selectedColor: const Color(0xFF007AFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}