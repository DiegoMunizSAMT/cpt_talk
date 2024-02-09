import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/database.dart';
import 'package:cpt_talk/templates/constants.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:cpt_talk/views/workflowchatscreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../helpers/authenticate.dart';
import 'chatscreen.dart';
import 'edituser.dart';

class ChatRoom extends StatefulWidget {
  const ChatRoom({Key? key}) : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  /// Specifica quale pagina è quella corrente (BottomNavigation).
  int _currentTabIndex = 0;

  TextEditingController searchBarText = TextEditingController();
  String search = '';
  String? mtoken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    loadUserInfo();

    requestPermission();
    getToken();
    initInfo();
  }

  void initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const IOSInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onSelectNotification: (String? payload) async {
      try {
        if (payload != null && payload.isNotEmpty) {
        } else {}
      } catch (e) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
          message.notification!.body.toString(),
          htmlFormatBigText: true,
          contentTitle: message.notification!.title.toString(),
          htmlFormatContentTitle: true);

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'CPTTalk',
        'CPTTalk',
        importance: Importance.high,
        styleInformation: bigTextStyleInformation,
        priority: Priority.high,
        playSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: const IOSNotificationDetails());
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
    } else {}
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
      });
      saveToken(mtoken!);
    });
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('utenti')
        .doc(Authenticate.firebaseAuth.currentUser?.uid as String)
        .update({'token': token});
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          "Authorization":
              'key=AAAAP7645XQ:APA91bFtAkUjaJyVyF0BbT829bX5DDLfW2JPoDImU5bDq7VNyLLSnlqCA1zCXyJKObBurj2Lta0txZAdGN8byAfDGb2VicmBWpCo0tXom8rs_FCSZgsTGuqakKwNj982d0NO6KUukQTG'
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "CPTTalk"
            },
          },
        ),
      );
    } catch (e) {}
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

    if (Constants.ruolo == 'contributore') {
      Constants.parentSid = (await Database.getParentSID(
          Authenticate.firebaseAuth.currentUser!.uid))!;
    }
  }

  /// Ritorna un TextField formattato che rappresenta la barra di ricerca
  /// dei canali.
  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: TextField(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade100)),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.all(10),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
            size: 20,
          ),
          hintText: "Cerca...",
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        controller: searchBarText,
        onChanged: (value) {
          setState(() {
            search = value;
          });
        },
      ),
    );
  }

  /// Ritorna la lista di canali presenti in Firestore. Questi canali sono
  /// filtrati in base alla ricerca effettuata tramite la barra di ricerca
  /// dei canali. Se non è presente nessuna ricerca, verranno mostrati
  /// tutti i canali.
  Widget chatRooms() {
    return Column(
      children: [
        searchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: Database.getChannelsStream(),
            builder: (context, snapshot) {
              List<Widget> children;

              /**
               * Gestisco una serie di errori che potrebbero occorrere con
               * lo snapshot.
               */
              if (snapshot.hasError) {
                children = <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Errore durante il caricamento delle chat!'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Riprova'),
                    ),
                  ),
                ];
              } else {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    children = const <Widget>[
                      Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 60,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Connessione assente!'),
                      )
                    ];
                    break;
                  case ConnectionState.waiting:
                    children = <Widget>[
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Caricando le chat...'),
                      )
                    ];
                    break;
                  case ConnectionState.active:
                    children = List<Widget>.empty();
                    break;
                  case ConnectionState.done:
                    children = <Widget>[
                      const Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 60,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Connessione terminata.'),
                      )
                    ];
                    break;
                }
              }

              /**
               * Se ci sono stati errori con lo snapshot, li mostro adesso.
               */
              if (children.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  ),
                );
              }

              /**
               * Ritorno la lista di canali. Se vi è stata una ricerca dei
               * canali, questa lista verrà filtrata e verranno mostrati i
               * canali che combaciano con il filtro. Se nessun canale combacia,
               * verrà mostrato un messaggio di errore.
               */

              var documents = snapshot.data!.docs;
              if (Constants.ruolo == "supervisore") {
                documents =
                    (documents.where((e) => e['public'] == false).toList());
              } else {
                documents = documents.where((element) {
                  Map<String, dynamic> data =
                      element.data() as Map<String, dynamic>;

                  if (data.containsKey("classi") &&
                          data["classi"].contains(Constants.sezione) ||
                      data.containsKey("classi") &&
                          data["classi"].contains("*")) {
                    return element.id
                        .toString()
                        .toLowerCase()
                        .contains(search.toLowerCase());
                  }

                  return false;
                }).toList();
              }

              if (documents.isNotEmpty) {
                return ListView.builder(
                  itemCount: documents.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 16),
                  itemBuilder: (context, index) {
                    return Channel(
                      name: documents[index].id,
                      description: documents[index]
                          [Constants.channelDescription],
                      public: documents[index]['public'],
                    );
                  },
                );
              } else {
                return const Center(child: Text('Nessun canale trovato.'));
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    /**
     * Lista dei contenuti delle varie pagine della navigazione.
     */
    final _tabPages = <Widget>[
      chatRooms(),
    ];

    return Scaffold(
      appBar: mainAppBarWithSignOut(context),
      body: _tabPages[_currentTabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(width: 2.0, color: Colors.red),
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        height: 60,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Column(
              //children: const <Widget>[
              //Icon(Icons.chat),
              //Text('Chat'),
              //],
              //),
              //SizedBox(
              //width: 24,
              //),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditUser(),
                    ),
                  );
                },
                child: Column(
                  children: const <Widget>[
                    Icon(Icons.person),
                    Text('Modifica utente'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stateless widget che rappresenta un elemento della lista dei canali, quindi,
/// rappresenta un canale, con il suo nome e la sua descrizione.
class Channel extends StatelessWidget {
  final String name;
  final String description;
  final bool public;

  const Channel(
      {Key? key,
      required this.name,
      required this.description,
      required this.public})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!public) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => WorkflowChatScreen(
                        title: name,
                      )));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatScreen(
                        title: name,
                      )));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            CircleAvatar(
              backgroundColor: public ? Colors.green : Colors.red,
              maxRadius: 30,
              child: public
                  ? const Icon(
                      Icons.lock_open,
                      color: Colors.black,
                    )
                  : const Icon(
                      Icons.lock_outline,
                      color: Colors.black,
                    ),
            ),
            const SizedBox(
              width: 16,
            ),
            Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
