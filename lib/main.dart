import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong2/latlong.dart" as latLng;
import 'package:http/http.dart' as http;
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:geojson/geojson.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:async';
import 'dart:convert' as convert;

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final mapController = MapController();
  GeoJsonParser myGeoJson = GeoJsonParser();

  TextEditingController loc1 = TextEditingController();
  TextEditingController loc2 = TextEditingController();

  double loc1_long = 0;
  double loc1_lat = 0;
  double loc2_long = 0;
  double loc2_lat = 0;

  List<latLng.LatLng> routes = [];
  final List<Polyline>lines = [];

  @override
  void initState() {
    super.initState();
    parseAndDrawAssetsOnMap();
  }

  Future getRoute(url) async{
    List<latLng.LatLng> route_list = [];
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
      final route_lonlat = jsonResponse["routes"][0]["geometry"]["coordinates"];
      for (int i =0 ; i<route_lonlat.length ; i++){
        route_list.add(latLng.LatLng(route_lonlat[i][1], route_lonlat[i][0]));
      }
      setState(() {
        routes = route_list;
      });
      ;
    }
    else {
      throw Exception("Failed to load album with status: ${response.statusCode}");
    }
  }

  Future<void> parseAndDrawAssetsOnMap() async {
    final geo = GeoJson();
    geo.processedLines.listen((GeoJsonLine line) {
      /// when a line is parsed add it to the map right away
      setState(() => lines.add(Polyline(
          strokeWidth: 2.0,
          color: Colors.blue,
          points: line.geoSerie!.toLatLng()))
      );
    });
    geo.endSignal.listen((_) => geo.dispose());
    final data = await rootBundle
        .loadString('assets/bulking_smart.json');
    await geo.parse(data, verbose: true);
  }

//   @override
  @override
  Widget build(BuildContext context) {
    double height_pct = MediaQuery.of(context).size.height;
    double width_pct = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Map"),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: latLng.LatLng(-2.74396599,112.91324255999999),
          zoom: 13.0,
        ),
        mapController: mapController,
        nonRotatedChildren: [
          AttributionWidget.defaultWidget(source: '© OpenStreetMap contributors'),
          Column(
            children: [
              Column(
                children: [
                  SizedBox(height: height_pct*0.01),
                  Container(
                    width: width_pct*0.3,
                    height: height_pct*0.05,
                    child: TextFormField(
                        controller: loc1,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),),
                            labelText: 'Start Location'
                        )
                    ),
                  ),
                  SizedBox(height: height_pct*0.01),
                  Container(
                    width: width_pct*0.3,
                    height: height_pct*0.05,
                    child: TextFormField(
                        controller: loc2,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),),
                            labelText: 'Destination'
                        )
                    ),
                  ),
                  SizedBox(height: height_pct*0.01),
                  Container(
                      width: width_pct*0.3,
                      height: height_pct*0.05,
                      child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              loc1_long = double.parse(loc1.text.replaceAll(RegExp(r',(?<=,).*'),''));
                              loc1_lat = double.parse(loc1.text.replaceAll(RegExp(r'.*(?=,),'),''));

                              loc2_long = double.parse(loc2.text.replaceAll(RegExp(r',(?<=,).*'),''));
                              loc2_lat =double.parse(loc2.text.replaceAll(RegExp(r'.*(?=,),'),''));

                              getRoute("http://router.project-osrm.org/route/v1/driving/"
                                  "${loc1_long},${loc1_lat};"
                                  "${loc2_long},${loc2_lat}?geometries=geojson");

                              lines.add(Polyline(
                                  points: routes,
                                  color: Colors.blue,
                                  strokeWidth: 4.0
                              ));
                            });

                          },
                          child: const Text("Search Route"))
                  ),
                ],
              ),
            ],
          ),

        ],
        children: [
          TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              additionalOptions: const {
                'accessToken' : 'pk.eyJ1Ijoic2F3YmVyc2luYXJtYXMiLCJhIjoiY2pzanZwaDFzMHo3djN5b2wwZ3h6dTE4NiJ9.i0GRqgAEzyvbT5h1d2NyUQ',
                'id' : 'mapbox://styles/sawbersinarmas/cjwrhn79t0idc1co2av87bhpx'
              },
              subdomains: ['a', 'b', 'c']
          ),
          PolylineLayer(
              polylineCulling: false,
              polylines: lines
          ),
          MarkerLayer(
            markers: [
              Marker(
                  point: latLng.LatLng(loc1_lat,loc1_long),
                  builder: (context) {
                    return Container(
                        child: Icon(
                          Icons.pin_drop,
                          color: Colors.yellow),
                        );
                  },
              ),
              Marker(
                point: latLng.LatLng(loc2_lat,loc2_long),
                builder: (context) {
                  return Container(
                      child: Icon(
                        Icons.pin_drop,
                        color: Colors.red),
                      );
                },
              )
            ],
          ),
        ]
      ),
    );
  }
}
