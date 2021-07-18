import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> messages;
  late double height;
  late double width;
  late TextEditingController edit;
  late ScrollController scroll;

  late Socket socket;

  @override
  void initState() {
    scroll = new ScrollController();
    edit = new TextEditingController();
    messages = [];
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    try {
      socket = io('http://127.0.0.1:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.on('connect', (_) => {print('connect: ${socket.id}')});
      socket.on('message', _receiveHandler);
      socket.on('disconnect', (_) => print('disconnect'));
      socket.on('fromServer', (_) => print(_));
      socket.connect();
    } catch (e) {
      print(e.toString());
    }
  }

  sendMessage(String message) {
    socket.emit(
      "message",
      {
        "id": socket.id,
        "message": message,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  _receiveHandler(dynamic data) {
    Map<String, dynamic> d = json.decode(data);
    if (d['id'] != socket.id) {
      this.setState(() => messages.add(d));

      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: Duration(milliseconds: 600),
        curve: Curves.ease,
      );
    }
  }

  Widget buildSingleMessage(int index) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        width: double.infinity,
        child: Align(
            alignment: isMyMessage(messages[index]['id'])
                ? Alignment.topRight
                : Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isMyMessage(messages[index]['id'])
                    ? Colors.deepPurple
                    : Colors.purple,
                borderRadius: BorderRadius.circular(16.0),
              ),
              width: MediaQuery.of(context).size.width * 0.65,
              child: Text(
                messages[index]['message'],
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            )),
      ),
    );
  }

  bool isMyMessage(id) {
    return id == socket.id;
  }

  Widget buildMessageList() {
    return Container(
      height: height * 0.8,
      width: width,
      child: ListView.builder(
        controller: scroll,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return buildSingleMessage(index);
        },
      ),
    );
  }

  Widget buildChatInput() {
    return Container(
        width: width * 0.7,
        padding: const EdgeInsets.all(2.0),
        margin: const EdgeInsets.only(left: 40.0),
        child: TextField(
            decoration: InputDecoration.collapsed(
              hintText: 'Send a message...',
            ),
            controller: edit));
  }

  Widget buildSendButton() {
    return FloatingActionButton(
      backgroundColor: Colors.deepPurple,
      onPressed: () {
        if (edit.text.isNotEmpty) {
          final m = {
            "id": socket.id,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            'message': edit.text
          };

          socket.emit('send_message', json.encode(m));
          this.setState(() => messages.add(m));
          edit.text = '';
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        }
      },
      child: Icon(
        Icons.send,
        size: 32,
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      height: height * 0.1,
      width: width,
      child: Row(children: <Widget>[
        buildChatInput(),
        buildSendButton(),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(children: <Widget>[
        SizedBox(height: height * 0.1),
        buildMessageList(),
        buildInputArea(),
      ])),
    );
  }
}
