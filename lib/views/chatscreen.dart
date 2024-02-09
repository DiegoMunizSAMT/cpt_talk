import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/database.dart';
import 'package:cpt_talk/helpers/simpledata.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../helpers/authenticate.dart';
import '../helpers/notifications.dart';
import '../templates/message.dart';

class ChatScreen extends StatefulWidget {
  final String title;

  const ChatScreen({Key? key, required this.title}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String currentUserSID;
  late Stream<QuerySnapshot> chats;
  bool internetConnection = false;
  TextEditingController message = TextEditingController();
  late ScrollController scrollController = ScrollController();

  /// Ritorna uno StreamBuilder che costruisce una lista di tutti i messaggi
  /// associati al canale in Firestore.
  Widget chatMessages() {
    return StreamBuilder(
      stream: Database.getMessages(widget.title),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        /**
         * Gestisco una serie di errori che potrebbero occorrere con
         * lo snapshot.
         */
        if (internetConnection) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(
                  Icons.wifi_off,
                  color: Colors.red,
                  size: 60,
                ),
                Text(
                    "Connessione internet assente, verificare la propria connessione."),
                Text(
                    "Se il problema sussiste contattare l'amministratore di rete.")
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Caricando le chat...'),
                )
              ],
            ),
          );
        }

        /**
         * Provo a creare una lista con i messaggi associati al canale. Se non
         * sono presenti messaggi nel canale, viene ritornato un
         * Container vuoto.
         */
        try {
          List<Map<String, dynamic>> messages =
              List.from(snapshot.data!['contenuto']);
          messages = messages
              .where((e) =>
                  e['messageTo'] == 'all' ||
                  e['messageTo'] ==
                      Authenticate.firebaseAuth.currentUser!.uid ||
                  e['sid'] == Authenticate.firebaseAuth.currentUser!.uid)
              .toList();
          messages = messages.reversed.toList();
          return messages.isNotEmpty
              ? ListView.builder(
                  controller: scrollController,
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    return Message(
                      message: messages.elementAt(index)['messaggio'],
                      username: messages.elementAt(index)['nome'],
                      sentByMe:
                          currentUserSID == messages.elementAt(index)['sid'],
                      timestamp: messages.elementAt(index)['creatoAlle'],
                    );
                  })
              : Container();
        } catch (e) {
          return Container();
        }
      },
    );
  }

  /// Permette di inviare un nuovo messagio, che viene passato da parametro.
  Future<void> sendMessage(String message) async {
    await Database.addMessage(widget.title, {
      "messaggio": message,
      "sid": currentUserSID,
      "creatoAlle": Timestamp.now(),
      "messageTo": "all",
    });
  }

  @override
  void initState() {
    super.initState();
    SimpleData.getSID().then((value) {
      currentUserSID = value!;
    });
    checkInternetConnection();
  }

  /// Il metodo controlla se è presente una connessione a internet
  Future<void> checkInternetConnection() async {
    internetConnection = !(await InternetConnectionChecker().hasConnection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: chatAppBar(context, widget.title),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 70),
            child: chatMessages(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(32)),
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Messaggio...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20)),
                        keyboardType: TextInputType.text,
                        controller: message,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(
                      Icons.send_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (message.text.isNotEmpty) {
                        await sendMessage(message.text);
                        Notifications.sendPushMessage(
                            message.text, widget.title);
                        message.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
