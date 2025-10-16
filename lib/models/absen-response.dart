// To parse this JSON data, do
//
//   final absenResponseModel = absenResponseModelFromJson(jsonString);

import 'dart:convert';

AbsenResponseModel absenResponseModelFromJson(String str) =>
    AbsenResponseModel.fromJson(json.decode(str) as Map<String, dynamic>);

String absenResponseModelToJson(AbsenResponseModel data) =>
    json.encode(data.toJson());

class AbsenResponseModel {
  final bool success;
  final String message;
  final List<Datum> data;

  AbsenResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AbsenResponseModel.fromJson(Map<String, dynamic> json) {
    // "data" bisa berupa List atau Map (kadang pagination: {"data": {...}})
    final rawData = json['data'];
    final list = <Datum>[];

    if (rawData is List) {
      for (final e in rawData) {
        if (e is Map<String, dynamic>) {
          list.add(Datum.fromJson(e));
        }
      }
    } else if (rawData is Map<String, dynamic>) {
      // kalau backend ngirim single object, tetap kita bungkus jadi list
      list.add(Datum.fromJson(rawData));
    }

    return AbsenResponseModel(
      success: _asBool(json['success']) ?? false,
      message: _asString(json['message']) ?? '',
      data: list,
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.map((x) => x.toJson()).toList(),
      };
}

class Datum {
  final int id;
  /// Tanggal dari backend (bisa "Kamis, 16 Oktober 2025" atau format lain).
  final String tanggal;

  /// Jam masuk/pulang bisa kosong saat belum presensi lengkap.
  final String jamMasuk;
  final String jamPulang; // biarkan string kosong "" jika null di payload

  final String status;
  final dynamic keterangan;

  /// Koordinat bisa dikirim sebagai string atau number; kita simpan sebagai string.
  final String latitudeMasuk;
  final String longitudeMasuk;
  final String latitudePulang;  // biarkan "" jika null
  final String longitudePulang; // biarkan "" jika null

  Datum({
    required this.id,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamPulang,
    required this.status,
    required this.keterangan,
    required this.latitudeMasuk,
    required this.longitudeMasuk,
    required this.latitudePulang,
    required this.longitudePulang,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: _asInt(json["id"]) ?? 0,
        tanggal: _asString(json["tanggal"]) ?? '',
        jamMasuk: _asString(json["jam_masuk"]) ?? '',
        jamPulang: _asString(json["jam_pulang"]) ?? '',               // aman untuk null
        status: _asString(json["status"]) ?? '',
        keterangan: json["keterangan"],
        latitudeMasuk: _asStringFlexible(json["latitude_masuk"]) ?? '',
        longitudeMasuk: _asStringFlexible(json["longitude_masuk"]) ?? '',
        latitudePulang: _asStringFlexible(json["latitude_pulang"]) ?? '',
        longitudePulang: _asStringFlexible(json["longitude_pulang"]) ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "tanggal": tanggal,
        "jam_masuk": jamMasuk,
        "jam_pulang": jamPulang,
        "status": status,
        "keterangan": keterangan,
        "latitude_masuk": latitudeMasuk,
        "longitude_masuk": longitudeMasuk,
        "latitude_pulang": latitudePulang,
        "longitude_pulang": longitudePulang,
      };
}

/// =====================
/// Helper parsing aman
/// =====================

bool? _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

/// Terima string atau number, tapi kembalikan sebagai string
String? _asStringFlexible(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toString();
  if (v is String) return v;
  return v.toString();
}
