import 'dart:convert';

SavePresensiResponseModel savePresensiResponseModelFromJson(String str) =>
    SavePresensiResponseModel.fromJson(json.decode(str));

String savePresensiResponseModelToJson(SavePresensiResponseModel data) =>
    json.encode(data.toJson());

class SavePresensiResponseModel {
  bool success;
  String message;
  Data data;

  SavePresensiResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SavePresensiResponseModel.fromJson(Map<String, dynamic> json) =>
      SavePresensiResponseModel(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  int id;
  int userId;
  DateTime tanggal;
  String jamMasuk;
  String latitudeMasuk;
  String longitudeMasuk;
  String jamPulang;
  String latitudePulang;
  String longitudePulang;
  String status;
  dynamic keterangan;
  DateTime createdAt;
  DateTime updatedAt;

  Data({
    required this.id,
    required this.userId,
    required this.tanggal,
    required this.jamMasuk,
    required this.latitudeMasuk,
    required this.longitudeMasuk,
    required this.jamPulang,
    required this.latitudePulang,
    required this.longitudePulang,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    userId: json["user_id"],
    tanggal: DateTime.parse(json["tanggal"]),
    jamMasuk: json["jam_masuk"],
    latitudeMasuk: json["latitude_masuk"],
    longitudeMasuk: json["longitude_masuk"],
    jamPulang: json["jam_pulang"],
    latitudePulang: json["latitude_pulang"],
    longitudePulang: json["longitude_pulang"],
    status: json["status"],
    keterangan: json["keterangan"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "tanggal":
        "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
    "jam_masuk": jamMasuk,
    "latitude_masuk": latitudeMasuk,
    "longitude_masuk": longitudeMasuk,
    "jam_pulang": jamPulang,
    "latitude_pulang": latitudePulang,
    "longitude_pulang": longitudePulang,
    "status": status,
    "keterangan": keterangan,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}
