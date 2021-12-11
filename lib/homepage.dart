import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distributed_app/restart.dart';
import 'package:flutter/material.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomePage extends StatefulWidget {
  // const HomePage({Key? key}) : super(key: key);
  // final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _myIP = "Unknown";
  String _currentLocation = "null";
  // Map _source = {ConnectivityResult.none: false};
  // final MyConnectivity _connectivity = MyConnectivity.instance;
  void initState() {
    super.initState();
    initPlatformState();
    // _connectivity.initialise();
    // _connectivity.myStream.listen((source) {
    //   setState(() => _source = source);
    // });
    initCurrentLocation();
  }

  Future<void> initPlatformState() async {
    String ip;
    try {
      if (await WifiInfo().getWifiIP() != null) {
        ip = (await WifiInfo().getWifiIP())!;
      } else {
        ip = "Unknown";
      }
    } on PlatformException {
      ip = "Failed to get";
    } on Null {
      ip = "Unknown";
    }
    setState(() {
      _myIP = ip;
    });
  }

  Future<void> initCurrentLocation() async {
    // String currentLocation;
    var currentLocation = FirebaseFirestore.instance
        .collection('IPdata')
        .doc('Location')
        .get()
        .then((val) {
      return val.data()!.entries.first.value;
    });
    currentLocation.then((value) => getCurrentLocation(value));
  }

  getCurrentLocation(currentLocation) {
    setState(() {
      _currentLocation = currentLocation;
    });
  }

  // callGetLocation() {
  //   var currentLocation = FirebaseFirestore.instance
  //       .collection('IPdata')
  //       .doc('Location')
  //       .get()
  //       .then((val) {
  //     return val.data()!.entries.first.value;
  //   });
  //   return currentLocation.then((value) => getCurrentLocation(value));
  // }

  @override
  Widget build(BuildContext context) {
    initPlatformState();
    // if (_currentLocation == "null") {
    //   print(_currentLocation);
    // }
    // String currentLocation = callGetLocation();
    // print(currentLocation);
    initCurrentLocation();
    if (_myIP == NullThrownError || _myIP == "Unknown") {
      return Container(
        child: Center(
          child: Text("NO INTERNET"),
        ),
      );
    } else {
      return Scaffold(
          body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 100, bottom: 50),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.contain,
                    image: AssetImage('assets/RIT_Logo.png'),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('IPdata')
                    .doc('IP-address')
                    .set({_myIP: 'Active'}, SetOptions(merge: true));

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => restartApp(_myIP)),
                );
              },
              child: const Text(
                'I am in the bus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            Text("Current Location:" + _currentLocation),
          ],
        ),
      ));
    }
  }
}

class MyConnectivity {
  MyConnectivity._();

  static final _instance = MyConnectivity._();
  static MyConnectivity get instance => _instance;
  final _connectivity = Connectivity();
  final _controller = StreamController.broadcast();
  Stream get myStream => _controller.stream;

  void initialise() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _checkStatus(result);
    _connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isOnline = false;
    }
    _controller.sink.add({result: isOnline});
  }

  void disposeStream() => _controller.close();
}
