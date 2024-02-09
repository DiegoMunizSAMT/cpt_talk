import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:cpt_talk/helpers/database.dart';
import 'package:cpt_talk/helpers/simpledata.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:cpt_talk/templates/workflowinput.dart';
import 'package:cpt_talk/templates/buttoninput.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../templates/message.dart';
import '../templates/constants.dart';
import '../templates/workflowmessage.dart';

List<Widget> messagesList = [];

class WorkflowChatScreen extends StatefulWidget {
  final String title;

  const WorkflowChatScreen({Key? key, required this.title}) : super(key: key);

  @override
  State<WorkflowChatScreen> createState() => _WorkflowChatScreenState();
}

class _WorkflowChatScreenState extends State<WorkflowChatScreen> {
  late String currentUserSID;
  late Stream<QuerySnapshot> chats;
  TextEditingController message = TextEditingController();
  late ScrollController scrollController = ScrollController();

  bool internetConnection = false;

  @override
  void initState() {
    super.initState();
    SimpleData.getSID().then((value) {
      currentUserSID = value!;
    });
    checkInternetConnection();
    loadUserInfo();
  }

  Future<void> checkInternetConnection() async {
    internetConnection = !(await InternetConnectionChecker().hasConnection);
  }

  Future<void> loadUserInfo() async {
    DocumentReference documentReference = FirebaseFirestore.instance
        .collection(Constants.collectionUtenti)
        .doc(Authenticate.firebaseAuth.currentUser!.uid);
    Constants.sezione = await documentReference.get().then((value) {
      return value.get("sezione");
    });

    Constants.ruolo = await documentReference.get().then((value) {
      return value.get("ruolo");
    });

    Constants.abilitato = await documentReference.get().then((value) {
      return value.get("abilitato");
    });

    Constants.abilitato = await documentReference.get().then((value) {
      return value.get("abilitato");
    });

    if (Constants.ruolo == 'contributore') {
      Constants.parentSid = (await Database.getParentSID(
          Authenticate.firebaseAuth.currentUser!.uid))!;
    }
  }

  /// Ritorna uno StreamBuilder che costruisce una lista di tutti i messaggi
  /// associati al canale in Firestore.
  Widget chatMessages() {
    if (Constants.ruolo == "contributore") {
      Database.startWorkflow(widget.title);
    }

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
          if (Constants.ruolo == "contributore") {
            messages = (messages
                .where((e) =>
                    e['sid'] == Authenticate.firebaseAuth.currentUser!.uid ||
                    e['waitingfor'] == Constants.parentSid)
                .toList());
          } else if (Constants.ruolo == "supervisore") {
            messages = messages
                .where((e) =>
                    e['sid'] == Authenticate.firebaseAuth.currentUser!.uid ||
                    e['waitingfor'] ==
                        Authenticate.firebaseAuth.currentUser!.uid ||
                    e['temporary'] == false)
                .toList();
          } else if (Constants.ruolo == "capolaboratorio") {
            messages = messages
                .where((e) =>
                    e['nome'] == "capolaboratorio" || e['temporary'] == false)
                .toList();
          }

          messages = messages.reversed.toList();
          return messages.isNotEmpty
              ? ListView.builder(
                  controller: scrollController,
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    if (messages.elementAt(index)['start']) {
                      return Workflow(
                        message: messages.elementAt(index)['messaggio'],
                        workflows:
                            List.from(messages.elementAt(index)['workflow']),
                        timestamp: messages.elementAt(index)['creatoAlle'],
                        start: messages.elementAt(index)['start'],
                        nome: "App",
                        channel: widget.title,
                        workflowposition: 0,
                      );
                    } else if (messages.elementAt(index)['type'] ==
                        "response") {
                      return const SizedBox.shrink();
                    } else if (messages.elementAt(index)['type'] ==
                        "question") {
                      return WorkflowInput(
                        input: messages.elementAt(index)['input'],
                        timestamp: messages.elementAt(index)['creatoAlle'],
                        channel: widget.title,
                        numeroDomanda:
                            messages.elementAt(index)['numeroDomanda'],
                        messaggio: messages.elementAt(index)['messaggio'],
                      );
                    } else if (messages.elementAt(index)['type'] == "wait") {
                      return ButtonInput(
                        message: messages.elementAt(index)['messaggio'],
                        buttons:
                            List.from(messages.elementAt(index)['options']),
                        timestamp: messages.elementAt(index)['creatoAlle'],
                        username: messages.elementAt(index)['nome'],
                        sentByMe: messages.elementAt(index)['waitingfor'] ==
                                Authenticate.firebaseAuth.currentUser?.uid ||
                            messages.elementAt(index)['waitingfor'] ==
                                Constants.ruolo,
                        channel: widget.title,
                        accepted: messages.elementAt(index)['accepted'] == null
                            ? -1
                            : messages.elementAt(index)['accepted']
                                ? 1
                                : 0,
                        workflowposition: 0,
                        id: messages.elementAt(index)['id'],
                        numeroDomanda:
                            messages.elementAt(index)['numeroDomanda'],
                        workflowName: messages.elementAt(index)['workflowName'],
                        sid: Constants.parentSid as String,
                        studentSid: messages.elementAt(index)['sid'],
                      );
                    } else {
                      return Message(
                        message: messages.elementAt(index)['messaggio'],
                        username: messages.elementAt(index)['nome'],
                        sentByMe: messages.elementAt(index)['sid'] ==
                            Authenticate.firebaseAuth.currentUser?.uid,
                        timestamp: messages.elementAt(index)['creatoAlle'],
                      );
                    }
                  })
              : Container();
        } catch (e) {
          return Container();
        }
      },
    );
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
          const Padding(
            padding: EdgeInsets.all(10),
            child: Align(alignment: Alignment.bottomLeft),
          ),
        ],
      ),
    );
  }
}
