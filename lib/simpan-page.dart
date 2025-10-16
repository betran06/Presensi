import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as myHttp;

// ← pastikan path import ini sesuai struktur project kamu
import 'package:presensi/models/save-presensi-response.dart';

class SimpanPage extends StatefulWidget {
  const SimpanPage({super.key});

  @override
  State<SimpanPage> createState() => _SimpanPageState();
}

class _SimpanPageState extends State<SimpanPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  static const Color kPrimary = Color.fromARGB(255, 135, 89, 164);
  static const Color kSurface = Color(0xFFF7F8FA);
  static const double kRadius = 16;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
  }

  // --- Location helper (fixed: requestService) ---
  Future<LocationData?> _currenctlocation() async {
    final location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      // Perbaikan: minta menyalakan service
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return null;
    }

    return await location.getLocation();
  }

  // --- Simpan presensi (pakai model, aman terhadap data null) ---
  Future<void> savePresensi(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat tidak tersedia')),
      );
      return;
    }

    final token = await _token;
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi berakhir. Silakan login ulang.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/save-presensi');

      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // penting untuk Laravel API
        // body Map -> form-url-encoded; kalau API butuh JSON body:
        // 'Content-Type': 'application/json',
      };

      final body = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };

      final response = await myHttp
          .post(
            uri,
            headers: headers,
            body: body,
            // kalau API butuh JSON, ganti:
            // body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      // Debug ringan (hapus jika tak perlu)
      // ignore: avoid_print
      print('[SAVE] status=${response.statusCode} body=${response.body}');

      bool success = response.statusCode >= 200 && response.statusCode < 300;
      String message = success ? 'Sukses Simpan Presensi' : 'Gagal Simpan Presensi';

      // Coba parse pakai model kamu. Jika "data" null / shape beda, fallback ke baca manual.
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          // kalau struktur persis dengan model
          if (decoded.containsKey('success') &&
              decoded.containsKey('message') &&
              decoded.containsKey('data')) {
            try {
              final model = SavePresensiResponseModel.fromJson(decoded);
              success = model.success;
              message = model.message;
              // model.data tersedia jika backend kirim; kalau tidak, parsing di atas bisa throw.
            } catch (_) {
              // kalau parsing model gagal (mis. data null),
              // baca minimal success/message secara manual
              final s = decoded['success'];
              if (s is bool) success = s;
              if (decoded['message'] != null) {
                message = decoded['message'].toString();
              }
            }
          } else {
            // fallback manual bila key tidak lengkap
            final s = decoded['success'];
            if (s is bool) success = s;
            if (decoded['message'] != null) {
              message = decoded['message'].toString();
            }
          }
        }
      } catch (_) {
        // body bukan JSON valid → biarkan pakai default message
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        // Tutup halaman & kirim sinyal sukses ke AbsenPage agar refresh
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$message (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan jaringan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refreshLocation() {
    setState(() {}); // memicu FutureBuilder memanggil ulang _currenctlocation()
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text("Simpan Presensi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Perbarui Lokasi',
            onPressed: _refreshLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: FutureBuilder<LocationData?>(
        future: _currenctlocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingSkeleton();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _errorPlaceholder(
              title: 'Lokasi tidak tersedia',
              message:
                  'Aktifkan layanan lokasi & izin GPS, lalu tap ikon Perbarui di kanan atas.',
              onRetry: _refreshLocation,
            );
          }

          final loc = snapshot.data!;
          final lat = loc.latitude;
          final lng = loc.longitude;
          final acc = _safeAccuracy(loc);
          final isMock = _safeIsMock(loc);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // MAP CARD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.black12.withOpacity(.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Header di atas peta
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kPrimary, Color(0xFF9E6CC8)],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.place_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lokasi Saat Ini',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Perbesar',
                              onPressed: () {},
                              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 280,
                        child: SfMaps(
                          layers: [
                            MapTileLayer(
                              initialFocalLatLng: MapLatLng(lat!, lng!),
                              initialZoomLevel: 15,
                              initialMarkersCount: 1,
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              markerBuilder: (BuildContext context, int index) {
                                return MapMarker(
                                  latitude: lat,
                                  longitude: lng,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Info koordinat
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _dot(color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.tune_rounded, size: 18, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    acc != null ? 'Perkiraan akurasi ~${acc.toStringAsFixed(0)} m' : 'Akurasi tidak tersedia',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            if (isMock == true) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sinyal mock location terdeteksi.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // INFO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_rounded, color: Colors.grey[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan titik lokasi sesuai. Tekan “Simpan Presensi” untuk mengirimkan koordinat saat ini.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // BUTTON SAVE
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : () => savePresensi(lat, lng),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Presensi',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // SECONDARY ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _isSaving ? null : _refreshLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Perbarui Lokasi'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== Helper UI =====

  Widget _loadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _box(double.infinity, 220, radius: kRadius),
        const SizedBox(height: 16),
        _box(double.infinity, 72, radius: kRadius),
        const SizedBox(height: 20),
        _box(double.infinity, 52, radius: 14),
      ],
    );
  }

  Widget _errorPlaceholder({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_disabled_rounded, size: 56, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
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

  Widget _dot({required Color color}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    );
  }

  double? _safeAccuracy(LocationData d) {
    try {
      final val = (d.accuracy is num) ? (d.accuracy as num).toDouble() : null;
      return val;
    } catch (_) {
      return null;
    }
  }

  bool? _safeIsMock(LocationData d) {
    try {
      final val = (d.isMock is bool) ? d.isMock as bool : null;
      return val;
    } catch (_) {
      return null;
    }
  }
}
