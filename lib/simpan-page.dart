import 'dart:convert';

import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
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

  @override
  void initState() {
    super.initState();

    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
  }

  Future<LocationData?> _currenctlocation() async {
    bool serviceEnable;
    PermissionStatus permissionGrated;

    Location location = new Location();

    serviceEnable = await location.serviceEnabled();
    print("KODING : TENGAH");

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

  Future savePresensi(latitude, longitude) async {
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

    savePresensiResponseModel = SavePresensiResponseModel.fromJson(json.decode(response.body));

    if (savePresensiResponseModel.success) {
      ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Sukses Simpan Presensi')));
      Navigator.canPop(context);
    } else {
       ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Gagal Simpan Presensi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("presensi"),
      ),
      body: FutureBuilder<LocationData?>(
        future: _currenctlocation(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final LocationData currenctlocation = snapshot.data;
            print(
              "KODING : " +
                  currenctlocation.latitude.toString() +
                  " | " +
                  currenctlocation.longitude.toString(),
            );
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 300,
                    child: SfMaps(
                      layers: [
                        MapTileLayer(
                          initialFocalLatLng: MapLatLng(
                            currenctlocation.latitude!,
                            currenctlocation.longitude!,
                          ),
                          initialZoomLevel: 15,
                          initialMarkersCount: 1,
                          urlTemplate:
                              "http://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          markerBuilder: (BuildContext context, int index) {
                            return MapMarker(
                              latitude: currenctlocation.latitude!,
                              longitude: currenctlocation.longitude!,
                              child: Icon(Icons.location_on, color: Colors.red),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      savePresensi(currenctlocation.latitude, currenctlocation.longitude);
                    },
                    child: Text("simpan presensi"),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
