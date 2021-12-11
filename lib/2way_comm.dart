import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Version_1/(Duplex + dynamic IP )",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: "Home Page",
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required String title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String sendingMessage = "";
  String reveivingMessage = "";
  String debuggingMessage = "This is for debugging";
  String myIP = "Unknown";

  @override
  void initState() {
    super.initState();
    print("Inside Initialization Function");

    // Initializing device IP address and receivingFunction
    getDeviceIP().then((value) => receivingFunction());
  }

  void receivingFunction() {
    print("Inside the receiving function");
    String receivingString = "Nothing Yet";
    helloFromTheOtherSide().then((value) => receivingString = value);
    print("Got message from that side");
    setState(() {
      reveivingMessage = receivingString;
    });
  }

  Future<String> helloFromTheOtherSide() async {
    String receivedMessage = "None";
    try {
      final listeningServer = await ServerSocket.bind(myIP, 4567);
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

  String handleConnection(Socket client) {
    print("inside handleConnection()");
    String _temp = "";
    print('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');

    client.listen(
      // handle data from the client
      (Uint8List data) async {
        await Future.delayed(Duration(seconds: 1));
        _temp = String.fromCharCodes(data);
        print("received data " + _temp);
        // return temp;
        setState(() {
          reveivingMessage = _temp;
        });
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

  Future<void> getDeviceIP() async {
    print("inside getDeviceIP()");
    String ip;
    try {
      ip = (await WifiInfo().getWifiIP())!;
      print("ip is " + ip);
    } on PlatformException {
      ip = "Failed to get";
    }
    setState(() {
      myIP = ip;
    });
  }

  sendMessage(messageToSend) async {
    setState(() {
      debuggingMessage = "sending message";
    });
    try {
      final sendingSocket = await Socket.connect("192.168.0.20", 4567);

      await send(sendingSocket, messageToSend);
    } on Exception catch (exception) {
      print("Got Exception in sendmessage " + exception.toString());
      setState(() {
        debuggingMessage = exception.toString();
      });
    } catch (error) {
      print("Got error in sendmessage " + error.toString());
      setState(() {
        debuggingMessage = error.toString();
      });
    }
  }

  Future<void> send(Socket socket, String message) async {
    print("sending this message to client: $message");
    setState(() {
      debuggingMessage = "sending message";
    });
    try {
      socket.write(message);
    } on Exception catch (exception) {
      print("Got Exception in send " + exception.toString());
      setState(() {
        debuggingMessage = exception.toString();
      });
    } catch (error) {
      print("Got error in send() " + error.toString());
      setState(() {
        debuggingMessage = error.toString();
      });
    }
    setState(() {
      debuggingMessage = "sent a message";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Testing 2way Communication")),
      body: Column(
        children: <Widget>[
          // Expanded(child: Text(myIP)),
          Expanded(child: TextInputWidget(this.sendMessage)),
          Expanded(child: Text(reveivingMessage)),
          Expanded(child: Text(debuggingMessage))
        ],
      ),
    );
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
