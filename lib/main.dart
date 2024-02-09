import 'package:cpt_talk/templates/constants.dart';
import 'package:cpt_talk/views/chatroom.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cpt_talk/views/signin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xml/xml.dart';

import 'helpers/database.dart';
import 'helpers/simpledata.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /**
   * Ottengo il contenuto del file XML con dentro le info API per la connessione
   * con Firebase.
   */
  //region XML reading
  final file = await rootBundle.loadString(
    'assets/config/firebase.xml',
  );
  final document = XmlDocument.parse(file);
  //endregion

  /**
   * Leggo i valori dell'API necessari per la connessione con Firebase dal
   * contenuto del file XML ricavato prima.
   * N.B.: Il valori dell'API sono quelli del DB Firebase in PRODUCTION,
   * se si avesse un DB in DEVELOPMENT si dovrebbe specificare nel file XML.
   */
  //region Firebase API values
  final basePath = document.getElement('firebase')!.getElement('production');
  String apiKey = '';
  String appId = '';
  String messagingSenderId = '';
  String projectId = '';

  if (basePath != null) {
    apiKey = basePath.getElement('apiKey')!.text;
    appId = basePath.getElement('appId')!.text;
    messagingSenderId = basePath.getElement('messagingSenderId')!.text;
    projectId = basePath.getElement('projectId')!.text;
  }
  //endregion

  /**
   * Istanzio la connessione con Firebase con i valori ricavati in precedenza.
   */
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId));

  await FirebaseMessaging.instance.getInitialMessage();

  /// Ricevere messaggi in background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Database.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? loggedIn;

  @override
  void initState() {
    isUserLoggedIn();
    super.initState();
  }

  /// Verifica se un utente è già loggato nell'applicazione.
  /// Imposta la variabile loggedIn in base all'esito del controllo.
  Future<void> isUserLoggedIn() async {
    await SimpleData.getLoginState().then((value) {
      setState(() {
        loggedIn = value;
      });
    });
  }

  Widget build(BuildContext context) {
    /**
     * Imposto il tipo di indicatore dei caricamenti.
     */
    EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.foldingCube;

    return MaterialApp(
      /**
       * Cambio il locale dell'applicazione.
       */
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate],
      supportedLocales: const [Constants.appLocale],
      debugShowCheckedModeBanner: false,
      /**
       * Imposto il tema dell'applicazione: diurno con colore rosso, e con
       * font family Ubuntu.
       */
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        primaryColor: Colors.red,
        fontFamily: Constants.ubuntuFontFamily,
      ),
      /**
       * Se l'utente è loggato, mostro la schermata dei canali. Invece se
       * l'utente non è loggato, viene mostrata la schermata di login.
       */
      home: loggedIn != null && loggedIn! ? const ChatRoom() : const SignIn(),
      /**
       * Inizializza EasyLoading.
       */
      builder: EasyLoading.init(),
    );
  }
}
