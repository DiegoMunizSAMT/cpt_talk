import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../templates/constants.dart';
import 'authenticate.dart';

/// La classe otifications permette di gestire le notifiche in arrivo.
class Notifications {
  String? mtoken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inizializzare le notifiche sia per Android che IOS
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

    /// Listener sul cloud messaging di Firebase che resta in ascolto per le nuove notifiche.
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

  /// Richiedere i permessi per le notifiche all'utente.
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

  /// Salva nelle informazioni dell'utente il token riferito al dispositivo che sta utilizzando.
  void saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('utenti')
        .doc(Authenticate.firebaseAuth.currentUser?.uid as String)
        .update({'token': token});
  }

  /// Il metodo invia un messaggio
  /// [body] il corpo del messaggio
  /// [title] il titolo della notifica
  /// [token] se viene specificato la notifica arriva al dispositivo specifico,
  /// altrimenti viene inviato a tutti (utilizzato per i canali pubblici)
  static void sendPushMessage(String title, String body,
      {String token = " "}) async {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAP7645XQ:APA91bFtAkUjaJyVyF0BbT829bX5DDLfW2JPoDImU5bDq7VNyLLSnlqCA1zCXyJKObBurj2Lta0txZAdGN8byAfDGb2VicmBWpCo0tXom8rs_FCSZgsTGuqakKwNj982d0NO6KUukQTG',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          "to": token == " " ? "/topics/$title" : token,
        },
      ),
    );
  }

  /// Metodo per iscriversi ai diversi canali
  static Future<void> subscribeToChannels() async {
    try {
      var doc = await _firestore.collection(Constants.collectionCanali).get();

      var docs = doc.docs;
      docs.forEach((element) {
        if (element.get('public')) {
          FirebaseMessaging.instance.subscribeToTopic(element.id);
        }
      });
    } catch (e) {
      print("subscribeToChannels() is not supported on Browser");
    }
  }
}
