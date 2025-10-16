import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/models/absen-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

/// Struktur UI untuk data absen
class AbsenItem {
  final String tanggalYMD; // YYYY-MM-DD
  final String masuk;
  final String pulang;
  final bool isHariIni;

  AbsenItem({
    required this.tanggalYMD,
    required this.masuk,
    required this.pulang,
    required this.isHariIni,
  });
}

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  AbsenItem? hariIni;
  final List<AbsenItem> riwayat = [];

  static const Color kPrimary = Color.fromARGB(255, 135, 89, 164);
  static const Color kSurface = Color(0xFFF7F8FA);
  static const double kRadius = 16;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((prefs) => prefs.getString("token") ?? "");
  }

  Future<void> getdata() async {
    try {
      final headers = {'Authorization': 'Bearer ${await _token}'};
      final response = await myHttp.get(
        Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Status: ${response.statusCode}');
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final model = AbsenResponseModel.fromJson(decoded);

      riwayat.clear();
      hariIni = null;

      final todayStr = _ymd(DateTime.now());
      DateTime? latestDate;
      AbsenItem? latestItem;

      for (final d in model.data) {
        final parsed = _parseTanggalID(d.tanggal) ?? DateTime.tryParse(d.tanggal);
        final ymd = parsed != null ? _ymd(parsed) : todayStr;

        final masuk = _normalizeTime(d.jamMasuk);
        final pulang = _normalizeTime(d.jamPulang);

        bool isToday = false;
        if (parsed != null) {
          final now = DateTime.now();
          isToday = parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
        }

        final item = AbsenItem(
          tanggalYMD: ymd,
          masuk: masuk,
          pulang: pulang,
          isHariIni: isToday,
        );

        if (isToday) {
          hariIni = item;
        } else {
          riwayat.add(item);
        }

        if (parsed != null && (latestDate == null || parsed.isAfter(latestDate))) {
          latestDate = parsed;
          latestItem = item;
        }
      }

      hariIni ??= latestItem;

      riwayat.sort((a, b) {
        final ad = DateTime.tryParse(a.tanggalYMD);
        final bd = DateTime.tryParse(b.tanggalYMD);
        if (ad == null || bd == null) return 0;
        return bd.compareTo(ad);
      });

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  // ---------------------------
  // Helper tanggal Indonesia
  // ---------------------------
  DateTime? _parseTanggalID(String s) {
    final cleaned = s.replaceAll(',', '').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    List<String> tokens = parts;
    if (tokens.length >= 4 && _isNamaHari(tokens[0])) tokens = tokens.sublist(1);
    if (tokens.length < 3) return null;

    final dd = int.tryParse(tokens[0]);
    final mm = _bulanKeAngka(tokens[1]);
    final yy = int.tryParse(tokens[2]);
    if (dd == null || mm == null || yy == null) return null;
    return DateTime(yy, mm, dd);
  }

  bool _isNamaHari(String w) {
    final lower = w.toLowerCase();
    return [
      'senin','selasa','rabu','kamis','jumat','jum\'at','sabtu','minggu',
      'min','sen','sel','rab','kam','jum','sab'
    ].contains(lower);
  }

  int? _bulanKeAngka(String b) {
    final lower = b.toLowerCase();
    const map = {
      'januari': 1, 'jan': 1,
      'februari': 2, 'feb': 2,
      'maret': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'mei': 5,
      'juni': 6, 'jun': 6,
      'juli': 7, 'jul': 7,
      'agustus': 8, 'agu': 8,
      'september': 9, 'sep': 9,
      'oktober': 10, 'okt': 10,
      'november': 11, 'nov': 11,
      'desember': 12, 'des': 12,
    };
    return map[lower];
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _normalizeTime(String s) {
    if (s.isEmpty || s == 'null' || s == '-') return '-';
    final m = RegExp(r'(\d{2}:\d{2}(:\d{2})?)').firstMatch(s);
    if (m != null) return m.group(1)!;
    return s;
  }

  String _formatDateID(DateTime d) {
    const hari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const bln = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${hari[d.weekday % 7]}, ${d.day} ${bln[d.month - 1]} ${d.year}';
  }

  String _prettyTanggal(String ymd) {
    try {
      final d = DateTime.parse(ymd);
      return _formatDateID(d);
    } catch (_) {
      return ymd;
    }
  }

  // ---------------------------
  // UI Section
  // ---------------------------
  Widget _simpleHeader(ThemeData theme) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.assignment_turned_in_rounded, color: kPrimary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Absensi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(_formatDateID(DateTime.now()), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        onPressed: () async => await getdata(),
      ),
    ],
  );

  Widget _todayCard(ThemeData theme) {
    final tglYMD = hariIni?.tanggalYMD ?? '-';
    final masuk = hariIni?.masuk ?? '-';
    final pulang = hariIni?.pulang ?? '-';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF9E6CC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                tglYMD == '-' ? '-' : _prettyTanggal(tglYMD),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _timeTile('Masuk', masuk, Icons.login_rounded)),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(.25)),
              Expanded(child: _timeTile('Pulang', pulang, Icons.logout_rounded)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, String time, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ]),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _historyItem(AbsenItem item, ThemeData theme) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.event_available_rounded, color: kPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(_prettyTanggal(item.tanggalYMD),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 8,
            children: [
              _pill('Masuk', item.masuk, Icons.login_rounded),
              _pill('Pulang', item.pulang, Icons.logout_rounded),
            ],
          ),
        ),
      ]),
    ),
  );

  Widget _pill(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(.1),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: kPrimary.withOpacity(.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: kPrimary),
      const SizedBox(width: 6),
      Text('$label: $value', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: kSurface,
      body: FutureBuilder(
        future: getdata(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: getdata,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: _simpleHeader(theme))),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _todayCard(theme))),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Riwayat Presensi',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (riwayat.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded, size: 42, color: Colors.grey[500]),
                            const SizedBox(height: 12),
                            const Text('Belum ada riwayat'),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: riwayat.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _historyItem(riwayat[index], theme)),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SimpanPage()),
          );
          if (result == true) await getdata();
        },
        backgroundColor: kPrimary,
        icon: const Icon(Icons.location_history),
        label: const Text('Presensi'),
      ),
    );
  }
}
