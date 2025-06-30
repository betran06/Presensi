import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name, _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
  }

  Future getdata() async {
    final Map<String, String> headres = {
      'Authorization': 'Bearer ' + await _token,
    };
    var response = await myHttp.get(
      Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
      headers: headres,
    );

    homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
    riwayat.clear();
    homeResponseModel!.data.forEach((element) {
      if (element.isHariIni) {
        hariIni = element;
      } else {
        riwayat.add(element);
      }
    });
    // print('DATA :'+ response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getdata(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder(
                      future: _name,
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else {
                          if (snapshot.hasData) {
                            print(snapshot.data);
                            return Text(
                              snapshot.data!,
                              style: TextStyle(fontSize: 18),
                            );
                          } else {
                            return Text("-");
                          }
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 135, 89, 164),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              hariIni?.tanggal ?? '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      hariIni?.masuk ?? '-',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      "Masuk",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      hariIni?.pulang ?? '-',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      "Pulang",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Riwayat Presensi"),
                    Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Tanggal
                                  Expanded(
                                    flex:
                                        3, // Lebih besar supaya muat teks panjang
                                    child: Text(
                                      riwayat[index].tanggal,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),

                                  // Jam Masuk
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          riwayat[index].masuk,
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        Text(
                                          "Masuk",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Jam Pulang
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          riwayat[index].pulang,
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        Text(
                                          "Pulang",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => SimpanPage()))
              .then((Value) => (Value));
        },
        child: Icon(Icons.location_history),
      ),
    );
  }
}
