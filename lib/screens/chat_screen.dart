import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;
User loggedInUser;
final messageController = TextEditingController();

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageText;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStreamBuilder(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageController.clear();
                      _fireStore.collection('message').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isAm});
  final String text;
  final String sender;
  final bool isAm;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isAm ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          Material(
            borderRadius: isAm
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isAm ? Colors.lightBlueAccent : Colors.grey,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                '$text  ',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStreamBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _fireStore
            .collection('message')
            .orderBy('time', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data.docs.reversed;
            List<MessageBubble> messageWidgets = [];
            for (var message in messages) {
              final messageTexts = message.data()['text'];
              final messageSender = message.data()["sender"];
              final currentUser = loggedInUser.email;
              final messageWidget = MessageBubble(
                text: messageTexts,
                sender: messageSender,
                isAm: currentUser == messageSender,
              );
              messageWidgets.add(messageWidget);
            }
            return Expanded(
              child: ListView(
                reverse: true,
                children: messageWidgets,
              ),
            );
          }
        });
  }
}
