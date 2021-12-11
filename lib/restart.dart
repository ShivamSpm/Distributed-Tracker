import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'bully.dart';

class restartApp extends StatefulWidget {
  String myIP;
  restartApp(this.myIP);

  @override
  _restartAppState createState() => _restartAppState();
}

class _restartAppState extends State<restartApp> {
  void restart() async {
    String received = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => Bully(widget.myIP)));

    // if (received == "restart") {
    restart();
    // }
  }

  @override
  void initState() {
    super.initState();
    new Timer(new Duration(seconds: 1), () {
      restart();
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Scaffold(
      body: Center(child: Text("RESTART")),
    );
  }
}
