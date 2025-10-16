import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presensi/absen-page.dart';
import 'package:presensi/login-page.dart';
import 'package:http/http.dart' as myHttp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name;

  static const Color kPrimary = Color.fromARGB(255, 135, 89, 164);
  static const Color kSurface = Color(0xFFF7F8FA);
  static const double kRadius = 16;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _name = _prefs.then((p) => p.getString('name') ?? '-');
  }

  String _greetingByTime() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _formatDateID(DateTime d) {
    const hari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const bln = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${hari[d.weekday % 7]}, ${d.day} ${bln[d.month - 1]} ${d.year}';
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title — segera hadir')),
    );
  }

  Future<void> _confirmAndLogout() async {
    if (_isLoggingOut) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda akan keluar dan perlu masuk kembali untuk menggunakan aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (ok != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      final prefs = await _prefs;
      final token = prefs.getString('token') ?? '';

      // Panggil API logout (sesuaikan jika endpoint kamu berbeda)
      try {
        await myHttp.post(
          Uri.parse('http://10.0.2.2:8000/api/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // best-effort: jika jaringan gagal, tetap lanjut hapus sesi lokal
      }

      await prefs.remove('token');
      await prefs.remove('name');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil logout')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 720;
            final crossAxisCount = isWide ? 3 : 2;
            final gridPadding = EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: 12,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: FutureBuilder<String>(
                      future: _name,
                      builder: (context, snap) {
                        final name = (snap.hasData && snap.data!.trim().isNotEmpty)
                            ? snap.data!.trim()
                            : '-';
                        return Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.badge_rounded, color: kPrimary, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greetingByTime(),
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.grey[700],
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateID(DateTime.now()),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol refresh (placeholder, jika diperlukan)
                            IconButton(
                              tooltip: 'Refresh',
                              onPressed: () {
                                // tambahkan aksi refresh home jika nanti ada data
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Refreshed')),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                            ),

                            // Tombol Logout
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: _isLoggingOut
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : IconButton(
                                      tooltip: 'Logout',
                                      onPressed: _confirmAndLogout,
                                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Subheader
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Text(
                      'Pintasan Fitur',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),

                  // Grid 2x2 / 3x? (responsif)
                  Padding(
                    padding: gridPadding,
                    child: GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.25 : 1.15,
                      ),
                      children: [
                        _FeatureTile(
                          color: kPrimary,
                          icon: Icons.location_history,
                          title: 'Absensi',
                          subtitle: 'Check-in / Check-out',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AbsenPage()),
                            );
                          },
                        ),
                        _FeatureTile(
                          color: const Color(0xFF23BB86),
                          icon: Icons.event_busy_rounded,
                          title: 'Pengajuan Absen',
                          subtitle: 'Cuti, Izin, sakit, dinas',
                          onTap: () => _comingSoon('Pengajuan Absen'),
                        ),
                        _FeatureTile(
                          color: const Color(0xFF04517E),
                          icon: Icons.schedule_rounded,
                          title: 'Lembur',
                          subtitle: 'Ajukan & catat lembur',
                          onTap: () => _comingSoon('Lembur'),
                        ),
                        _FeatureTile(
                          color: const Color(0xFF2E7462),
                          icon: Icons.calendar_month_rounded,
                          title: 'Mapping Calender',
                          subtitle: 'Jam & toleransi',
                          onTap: () => _comingSoon('Mapping Calender'),
                        ),
                      ],
                    ),
                  ),

                  // Info kecil (opsional)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.black12.withOpacity(.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_rounded, color: Colors.grey[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gunakan tombol di atas untuk mengakses fitur. Detail presensi ada di halaman Absensi.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_HomePageState.kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_HomePageState.kRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
