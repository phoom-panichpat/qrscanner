import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:snscanner/firebase_options.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final List _scanResult = [];
  final List _dateResult = [];
  final List _latResult = [];
  final List _longResult = [];

  String lat = 'loading';
  String long = 'loading';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Failed'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SN submitted'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String getDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    return formattedDate;
  }

  Future<void> scanCode(now, lt, lng) async {
    String barcodeScanResult;

    try {
      barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      _scanResult.add(barcodeScanResult);
      _dateResult.add(now);
      _latResult.add(lat);
      _longResult.add(long);
    } on PlatformException {
      _showMyDialog();
    }
    setState(() {});
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      lat = position.latitude.toString();
      long = position.longitude.toString();

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _determinePosition().then((value) {
      lat = value.latitude.toString();
      long = value.longitude.toString();
    });
    _liveLocation();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          scanCode(getDate(), lat, long);
          debugPrint(' $_scanResult,$_dateResult');
        },
        child: const Icon(Icons.qr_code),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ListView.builder(
              // shrinkWrap: true,
              itemCount: _scanResult.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _scanResult[index].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${_dateResult[index].toString()} \n ${_latResult[index].toString()}, ${_longResult[index].toString()}',
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  debugPrint('$lat $long');
                  _scanResult.clear();
                  _dateResult.clear();
                  _latResult.clear();
                  _longResult.clear();
                  _submitDialog();
                  debugPrint(' $_scanResult,$_dateResult');
                  setState(() {});
                },
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(200, 40)),
                child: const Text('Submit'),
              ),
              ElevatedButton(
                onPressed: () {
                  _scanResult.removeLast();
                  _dateResult.removeLast();
                  _latResult.removeLast();
                  _longResult.removeLast();
                  debugPrint(' $_scanResult,$_dateResult');
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    backgroundColor: const Color(0xFFFFE5EC)),
                child: const Text('-'),
              ),
            ],
          ),
          const SizedBox(
            height: 140,
          ),
        ],
      ),
    );
  }
}
