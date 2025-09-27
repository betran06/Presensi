import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  // === STATE & PREF ===
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  // === THEME TOKENS (ringan, no dependency) ===
  static const Color kPrimary = Color.fromARGB(255, 135, 89, 164);
  static const Color kSurface = Color(0xFFF7F8FA);
  static const double kRadius = 16;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((prefs) => prefs.getString("token") ?? "");
  }

  // === DATA FETCH (tetap sama endpoint & alur) ===
  Future getdata() async {
    final Map<String, String> headres = {
      'Authorization': 'Bearer ' + await _token,
    };
    final response = await myHttp.get(
      Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
      headers: headres,
    );

    homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
    riwayat.clear();
    hariIni = null;

    for (final element in homeResponseModel!.data) {
      if (element.isHariIni) {
        hariIni = element;
      } else {
        riwayat.add(element);
      }
    }
  }

  // === UI HELPERS ===
  String _formatDateID(DateTime d) {
    const hari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const bln = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${hari[d.weekday % 7]}, ${d.day} ${bln[d.month - 1]} ${d.year}';
  }

  Widget _simpleHeader(ThemeData theme) {
    return Row(
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
              Text('Absensi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(
                _formatDateID(DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () async {
            await getdata();
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _todayCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, Color(0xFF9E6CC8)],
        ),
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tanggal
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  hariIni?.tanggal ?? '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Jam masuk & pulang
            Row(
              children: [
                Expanded(child: _timeTile('Masuk', hariIni?.masuk ?? '-', Icons.login_rounded)),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(.25),
                ),
                Expanded(child: _timeTile('Pulang', hariIni?.pulang ?? '-', Icons.logout_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            // Keterangan kecil (opsional)
            Text(
              'Ringkasan presensi hari ini',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyHeader(ThemeData theme) {
    return Row(
      children: [
        Text('Riwayat Presensi',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Icon(Icons.filter_list_rounded, color: Colors.grey[700]),
      ],
    );
  }

  Widget _historyItem(Datum item, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_available_rounded, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                item.tanggal,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  _pill('Masuk', item.masuk, Icons.login_rounded),
                  _pill('Pulang', item.pulang, Icons.logout_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kPrimary.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // header skeleton sederhana
          Row(
            children: [
              _box(48, 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(child: _box(double.infinity, 18)),
            ],
          ),
          const SizedBox(height: 20),
          _box(double.infinity, 140, radius: kRadius),
          const SizedBox(height: 20),
          _box(double.infinity, 18),
          const SizedBox(height: 12),
          ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _box(double.infinity, 72, radius: kRadius),
              )),
        ],
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 8}) {
    return Container(
      width: w == double.infinity ? double.infinity : w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kSurface,
      body: FutureBuilder(
        future: getdata(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SafeArea(child: _loadingSkeleton());
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await getdata();
                if (mounted) setState(() {});
              },
              child: CustomScrollView(
                slivers: [
                  // Header sederhana: judul + tanggal + refresh
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _simpleHeader(theme),
                    ),
                  ),

                  // Kartu Hari Ini
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _todayCard(theme),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Header riwayat
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _historyHeader(theme),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Daftar Riwayat
                  riwayat.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 42, color: Colors.grey[500]),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tarik ke bawah untuk memuat ulang.',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: riwayat.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = riwayat[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _historyItem(item, theme),
                            );
                          },
                        ),

                  // Bottom spacing biar list tidak ketutup FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const SimpanPage()))
              .then((Value) => (Value));
        },
        backgroundColor: kPrimary,
        icon: const Icon(Icons.location_history),
        label: const Text('Presensi'),
      ),
    );
  }
}
