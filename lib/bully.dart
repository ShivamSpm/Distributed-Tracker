// ignore_for_file: curly_braces_in_flow_control_structures, non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distributed_app/homepage.dart';
import 'package:flutter/material.dart';

// cc:bd:fe:e6:95:70:88:bd:32:7b:bc:ca:a2:e7:a4:44:9c:26:87:d7
// c5:c0:0e:ba:fc:6d:9b:47:62:5e:70:a3:d4:85:03:2b:50:0d:fa:83:b6:f4:a7:26:9f:c1:0c:35:d6:19:ca:dc

class Bully extends StatefulWidget {
  String myIP;
  Bully(this.myIP);

  @override
  _BullyState createState() => _BullyState();
}

class _BullyState extends State<Bully> {
  String sendingMessage = "";
  String receivingMessage = "";
  String debuggingMessage = "This is for debugging";
  bool updatingLocation = true;
  bool callingLeader = true;
  String insideBus = "Yes";
  late ServerSocket SOK;
  String _printLeader = "";

  @override
  void initState() {
    super.initState();
    // print("Inside Initialization Function");

    //receivingFunction
    receivingFunction();

    //if no leader
    leaderCheck();
    initPrintLeader();
    // leaderOrworker();
  }

  void leaderCheck() {
    callingLeader = true;
    //Generate random time
    var rng = new Random();
    var randomNum = rng.nextInt(6000);

    // Add random timer

    new Timer(new Duration(milliseconds: randomNum), () {
      print(randomNum);
    });

    var currentLeader = FirebaseFirestore.instance
        .collection('IPdata')
        .doc('Current_Leader')
        .get()
        .then((val) {
      return val.data();
    });
    currentLeader.then((value) => leaderOrworker(value));
  }

  void leaderOrworker(entry) {
    if (entry!.isEmpty) {
      print("%%%%%%%%%%%%%%%%%% Leader is empty");

      FirebaseFirestore.instance
          .collection('IPdata')
          .doc('Current_Leader')
          .set({"leader": widget.myIP}, SetOptions(merge: true));

      keepupdatinglocation();
    } else {
      print("-------------------------- Leader is not empty");

      var leaderip = FirebaseFirestore.instance
          .collection('IPdata')
          .doc('Current_Leader')
          .get()
          .then((val) {
        return val.data()!.entries.first.value;
      });

      leaderip.then((value) => keepcallingLeader(value));
    }
  }

  void keepupdatinglocation() async {
    while (updatingLocation) {
      DateTime today = DateTime.now();
      String time = "${today.minute.toString()}-${today.second.toString()}";
      FirebaseFirestore.instance
          .collection('IPdata')
          .doc('Location')
          .set({"location": time}, SetOptions(merge: true));

      await Future.delayed(Duration(seconds: 3));
    }
  }

  void keepcallingLeader(value) async {
    while (true) {
      sendMessagetoIP(value, "Alive?");
      await Future.delayed(Duration(seconds: 5));
    }
  }

  // Function Keeps On Listening
  void receivingFunction() {
    print("Inside the receiving function");
    String receivingString = "Nothing Yet";
    helloFromTheOtherSide().then((value) => receivingString = value);
    // print("Got message from that side");
    if (mounted) {
      setState(() {
        receivingMessage = receivingString;
      });
    }
  }

  // Function Opens Listening Port
  Future<String> helloFromTheOtherSide() async {
    String receivedMessage = "None";
    try {
      final listeningServer =
          await ServerSocket.bind(widget.myIP, 4567, shared: true);
      SOK = listeningServer;
      listeningServer.listen((client) {
        print("listening...");
        receivedMessage = handleConnection(client);
      });
    } on Exception catch (exception) {
      print("got an exception :" + exception.toString());
    } catch (error) {
      print("got an error :" + error.toString());
    }
    return receivedMessage;
  }

  //Function Handles Connection
  String handleConnection(Socket client) {
    // print("inside handleConnection()");
    String _temp = "";
    print('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');

    client.listen(
      // handle data from the client
      (Uint8List data) async {
        await Future.delayed(Duration(seconds: 1));
        _temp = String.fromCharCodes(data);
        print("received data " + _temp);

        // Handle Incoming Messages;
        if (_temp == "Alive?") {
          sendMessagetoIP(client.remoteAddress.address, "Yes");
        }
        if (mounted) {
          setState(() {
            receivingMessage = _temp;
          });
        }
      },
      // handle errors
      onError: (error) {
        print(error);
        client.close();
      },
      // handle the client closing the connection
      onDone: () {
        print('Client left');
        client.close();
      },
    );
    return _temp;
  }

  // Function Sends Message TO IP
  // sendMessage(messageToSend) async {
  //   var IPs = await getAllIPs();
  //   IPs.forEach((key, value) {
  //     if (key != widget.myIP) {
  //       sendMessagetoIP(key, messageToSend);
  //     }
  //   });
  // }

  sendMessagetoIP(ip, messageToSend) async {
    if (ip != widget.myIP) {
      print("sendMessagetoIP " + ip + " message is " + messageToSend);
      // setState(() {
      //   debuggingMessage = "sending message $messageToSend to $ip";
      // });
      Socket? sendingSocket = null;
      try {
        sendingSocket = await Socket.connect(ip, 4567);
        send(sendingSocket, messageToSend);
      } on Exception catch (exception) {
        if (messageToSend == "Alive?") {
          if (sendingSocket != null) sendingSocket.destroy();

          Future.delayed(const Duration(seconds: 1));

          // pop
          if (context != null) {
            Navigator.pop(context, "restart");
          }
        }

        print("Got Exception in sendmessage " + exception.toString());
        if (mounted) {
          setState(() {
            debuggingMessage =
                exception.toString() + " Setting himself as leader";
          });
        }
      } catch (error) {
        print("Got error in sendmessage " + error.toString());
        if (mounted) {
          setState(() {
            debuggingMessage = error.toString();
          });
        }
      }
    }
  }

  getAllIPs() async {
    var totalIPs = await FirebaseFirestore.instance
        .collection('IPdata')
        .doc('IP-address')
        .get()
        .then((val) {
      return val.data();
    });
    return totalIPs;
  }

  send(Socket socket, String message) {
    // print("sending this message to client: $message");
    if (mounted) {
      setState(() {
        debuggingMessage = "sending message";
      });
    }
    try {
      socket.write(message);
    } on Exception catch (exception) {
      print("Got Exception in send " + exception.toString());
      if (mounted) {
        setState(() {
          debuggingMessage = exception.toString();
        });
      }
    } catch (error) {
      print("Got error in send() " + error.toString());
      if (mounted) {
        setState(() {
          debuggingMessage = error.toString();
        });
      }
    }
    if (mounted) {
      setState(() {
        debuggingMessage = "sent a message";
      });
    }
  }

  @override
  void dispose() {
    SOK.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initPrintLeader();
    if (_printLeader != widget.myIP) {
      setState(() {
        _printLeader = "";
      });
    } else {
      setState(() {
        _printLeader = "You are the leader";
      });
    }

    return Scaffold(
        appBar: AppBar(title: const Text("Distributed Tracker")),
        body: Center(
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Expanded(child: Text(myIP)),
              // Expanded(child: TextInputWidget(this.sendMessage)),
              Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Text(_printLeader),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Text(receivingMessage),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Text(debuggingMessage),
              ),

              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('IPdata')
                      .doc('IP-address')
                      .set({widget.myIP: FieldValue.delete()},
                          SetOptions(merge: true));
                  var leader = FirebaseFirestore.instance
                      .collection('IPdata')
                      .doc('Current_Leader')
                      .get()
                      .then((val) {
                    return val.data()!.entries.first.value;
                  });

                  leader.then((value) => deleteLeader(value));

                  new Timer(const Duration(seconds: 1), () async {
                    exit(0);
                  });

                  // sendMessagetoIP(widget.myIP, "STOP");
                  // updatingLocation = false;
                },
                child: Text('I am out of the bus'),
              ),
            ],
          ),
        ));
  }

  deleteLeader(value) {
    if (widget.myIP == value) {
      FirebaseFirestore.instance
          .collection('IPdata')
          .doc('Current_Leader')
          .set({"leader": FieldValue.delete()}, SetOptions(merge: true));
    }
  }

  Future<void> initPrintLeader() async {
    var currentLeader = FirebaseFirestore.instance
        .collection('IPdata')
        .doc('Current_Leader')
        .get()
        .then((val) {
      return val.data()!.entries.first.value;
    });
    currentLeader.then((value) => getLeader(value));
  }

  getLeader(value) {
    setState(() {
      _printLeader = value;
    });
  }
}

class TextInputWidget extends StatefulWidget {
  // const TextInputWidget({ Key? key }) : super(key: key);

  final Function(String) callback;
  TextInputWidget(this.callback);

  @override
  _TextInputWidgetState createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  void click() {
    widget.callback(controller.text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          prefixIcon: Icon(Icons.message),
          labelText: "Please Enter a Message",
          suffixIcon: IconButton(
            icon: Icon(Icons.send),
            onPressed: click,
          )),
    );
  }
}
