import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:presensi/models/save-presensi-response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as myHttp;

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

  // NOTE: logic tetap sama seperti kode kamu (tidak diubah)
  Future<LocationData?> _currenctlocation() async {
    bool serviceEnable;
    PermissionStatus permissionGrated;

    Location location = Location();

    serviceEnable = await location.serviceEnabled();
    if (!serviceEnable) {
      serviceEnable = await location.serviceEnabled();
      if (!serviceEnable) {
        return null;
      }
    }

    permissionGrated = await location.hasPermission();
    if (permissionGrated == PermissionStatus.denied) {
      permissionGrated = await location.requestPermission();
      if (permissionGrated != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  // NOTE: alur backend tetap sama — hanya tambah indikator loading
  Future savePresensi(latitude, longitude) async {
    setState(() => _isSaving = true);
    try {
      SavePresensiResponseModel savePresensiResponseModel;
      Map<String, String> body = {
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
      };

      Map<String, String> headers = {'Authorization': 'Bearer ' + await _token};

      var response = await myHttp.post(
        Uri.parse('http://10.0.2.2:8000/api/save-presensi'),
        body: body,
        headers: headers,
      );

      savePresensiResponseModel = SavePresensiResponseModel.fromJson(
        json.decode(response.body),
      );

      if (!mounted) return;
      if (savePresensiResponseModel.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sukses Simpan Presensi')));
        // Tetap mengikuti kode kamu (tidak memaksa pop):
        Navigator.canPop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal Simpan Presensi')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refreshLocation() {
    // Cukup panggil setState agar FutureBuilder memanggil ulang _currenctlocation()
    setState(() {});
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
        builder: (BuildContext context, AsyncSnapshot<LocationData?> snapshot) {
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

          final LocationData currenctlocation = snapshot.data!;
          final lat = currenctlocation.latitude;
          final lng = currenctlocation.longitude;
          final acc = _safeAccuracy(currenctlocation);
          final isMock = _safeIsMock(currenctlocation);

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
                      // Header kecil di atas peta
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                              child: const Icon(
                                Icons.place_rounded,
                                color: Colors.white,
                              ),
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
                              onPressed: () {
                                // Placeholder (tanpa ubah alur): bisa dikembangkan untuk fullscreen map
                              },
                              icon: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                              ),
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
                              // pakai HTTPS biar aman dari block mixed-content
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              markerBuilder: (BuildContext context, int index) {
                                return MapMarker(
                                  latitude: lat,
                                  longitude: lng,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Info koordinat & akurasi
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    acc != null
                                        ? 'Perkiraan akurasi ~${acc.toStringAsFixed(0)} m'
                                        : 'Akurasi tidak tersedia',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isMock != null && isMock) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sinyal mock location terdeteksi.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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

                // INFO COPY
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : () => savePresensi(lat, lng),
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                            ),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Presensi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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
            Icon(
              Icons.location_disabled_rounded,
              size: 56,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  double? _safeAccuracy(LocationData d) {
    try {
      // beberapa versi plugin menyediakan d.accuracy
      final val = (d.accuracy is num) ? (d.accuracy as num).toDouble() : null;
      return val;
    } catch (_) {
      return null;
    }
  }

  bool? _safeIsMock(LocationData d) {
    try {
      // beberapa versi plugin menyediakan d.isMock
      final val = (d.isMock is bool) ? d.isMock as bool : null;
      return val;
    } catch (_) {
      return null;
    }
  }
}
