import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:cpt_talk/templates/constants.dart';

import 'notifications.dart';

class Database {
  //region Properties
  /// Indica se il il metodo init() è già stato invocato.
  static bool _initialized = false;

  /// Istanza di Firestore che permette di gestire tutte le DDL.
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Liste contenenti le sezioni e le classi del CPT.
  static final List<String> sezioni = [];
  static final List<String> classi = [];

  /// Lista contenente i ruoli del CPT Talk.
  static const List<String> ruoli = Constants.roles;

  //endregion

  /// Riferimenti a tutte le collection in Firestore.
  //region Collections
  static final CollectionReference _collectionUtenti =
      _firestore.collection(Constants.collectionUtenti);
  static final CollectionReference _collectionSezioni =
      _firestore.collection(Constants.collectionSezioni);
  static final CollectionReference _collectionCanali =
      _firestore.collection(Constants.collectionCanali);
  static final CollectionReference _collectionParametri =
      _firestore.collection(Constants.collectionParametri);
  static final CollectionReference _collectionMessaggi =
      _firestore.collection(Constants.collectionMessaggi);
  static final CollectionReference _collectionWorkflow =
      _firestore.collection(Constants.collectionWorkflow);

  //endregion

  //region Utility
  /// Permette di leggere le sezioni e le classi all'inizializzazione del DB.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    QuerySnapshot sections = await _collectionSezioni.get();

    for (var doc in sections.docs) {
      sezioni.add(doc.id);

      Map<String, dynamic> sectionClasses = doc.data() as Map<String, dynamic>;
      sectionClasses.forEach((key, value) {
        if (key == "classi") {
          value.forEach((classe) => classi.add(classe));
        }
      });
    }

    classi.sort();
  }

  /// Permette di stabilire se un numero di telefono è gia esistente.
  static Future<String?> checkIfTelExists(String tel) async {
    var docs = await _collectionUtenti.where('tel', isEqualTo: tel).get();
    return docs.size > 0 ? docs.docs[0].id : null;
  }

  /// Permette di stabilire se il codice docenti inserito è corretto.
  static Future<bool> isATeacher(String code) async {
    DocumentReference docenti =
        _collectionParametri.doc(Constants.documentParametriDocenti);

    String teacherCode = '';
    await docenti.get().then((snapshot) {
      teacherCode = snapshot.get('codice');
    });

    return teacherCode == code;
  }

  //endregion

  //region Getters
  /// Ritorna lo stream contenente tutti gli utenti in Firestore.
  /// Se specificato, si può scegliere di includere anche il proprio utente.
  static Stream<QuerySnapshot> getUsersStream(bool selfIncluded) {
    return selfIncluded
        ? _collectionUtenti.snapshots()
        : _collectionUtenti
            .where('sid',
                isNotEqualTo: Authenticate.firebaseAuth.currentUser!.uid)
            .snapshots();
  }

  /// Ritorna lo stream di tutti i canali presenti in Firestore.
  static Stream<QuerySnapshot> getChannelsStream() {
    Notifications.subscribeToChannels();
    return _firestore.collection(Constants.collectionCanali).snapshots();
  }

  /// Ritorna il SID dell'utente che possiede il numero di telefono passato
  /// da parametro.
  static Future<String?> getChildSID(String phoneNumber) async {
    var docs = await _collectionUtenti
        .where('ruolo', isEqualTo: 'contributore')
        .where('tel', isEqualTo: phoneNumber)
        .get();
    return docs.size > 0 ? docs.docs[0].id : null;
  }

  static Future<String?> getParentSID(String sid) async {
    var docs;

    docs = await _collectionUtenti
        .where('ruolo', isEqualTo: 'supervisore')
        .where('supervisionati', arrayContains: sid)
        .get();
    return docs.size > 0 ? docs.docs[0].id : null;
  }

  /// Ritorna una lista sommario dei figli che sono stati scelti da un genitore
  /// in base alla lista di SID dei figli passata da parametro.
  static Future<List<Map<String, String>>> getChildrenSummary(
      List<String> children) async {
    List<Map<String, String>> summary = [];
    for (var child in children) {
      var doc = await _collectionUtenti.doc(child).get();

      String fullname = doc['nome'] + " " + doc['cognome'];
      String phoneNumber = doc['tel'];

      summary.add({'child': fullname, 'phoneNumber': phoneNumber});
    }
    return summary;
  }

  /// Ritorna lo stream dei messaggi di un canale.
  static Stream<DocumentSnapshot> getMessages(String channel) {
    return _collectionMessaggi.doc(channel).snapshots();
  }

  /// Ritorna l'elemento che contiene la risposta di una domanda
  /// di una conversazione e domanda precisa.
  /// [channel] è il canale di cui si vuole avere l'informazione
  /// [id] è l'id della conversazione
  /// [numeroDomanda] è il numero della domanda
  static Future<bool> getWorkflowResponse(
      int id, int numeroDomanda, channel) async {
    List messages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    messages = doc['contenuto'];
    messages = messages
        .where((e) => e['numeroDomanda'] == numeroDomanda || e['id'] == id)
        .toList();
    return messages[0]['accepted'];
  }

  /// Ritorna il contributore proprietario di uno specifico workflow
  /// [id] è l'id della conversazione
  /// [channel] è il canale dove si sta cercando
  static Future<String> getWorkflowSid(int id, String channel) async {
    List messages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    messages = doc['contenuto'];
    return messages[0]['sid'];
  }

  /// Ritorna il nome di un utente in base al SID passato da parametro.
  static Future<String?> getUsernameById(String sid) async {
    var doc = await _collectionUtenti.doc(sid).get();
    return doc['nome'];
  }

  /// Ritorna il nome di un utente in base al SID passato da parametro.
  static Future<String?> getTokenById(String sid) async {
    var doc = await _collectionUtenti.doc(sid).get();
    return doc['token'];
  }

  /// Scarica l'ultimo id utilizzato per il canale [channel],
  /// in seguito aggiorna l'id sul db.
  static Future<void> saveLastUsedId(String channel) async {
    var doc = await _collectionMessaggi.doc(channel).get();
    Constants.workflowId = doc['lastUsedId'];
    incrementLastUsedId(channel);
  }

  /// Incrementa il campo 'lastUsedId' per uno specifico canale ([channel]).
  static Future<void> incrementLastUsedId(String channel) async {
    await _collectionMessaggi
        .doc(channel)
        .update({'lastUsedId': Constants.workflowId + 1});
  }

  /// Rimuove dal db tutti i messaggi con il campo 'temporary' con valore true.
  /// [channel] è il canale da cui rimuovere gli elementi
  static Future<void> removeTemporaryMessages(String channel) async {
    List _modifiedMessages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    _modifiedMessages = doc['contenuto']
        .where((i) =>
            i['temporary'] == false ||
            i['action'].toString().startsWith("wait"))
        .toList();

    await _collectionMessaggi.doc(channel).set({
      'contenuto': _modifiedMessages,
      'lastUsedId': Constants.workflowId + 1
    });
  }

  /// Rimuove dal db tutti i messaggi con il campo 'temporary' con valore true.
  /// [channel] è il canale da cui rimuovere gli elementi
  static Future<void> removeFirstMessages(String channel) async {
    List _modifiedMessages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    _modifiedMessages =
        doc['contenuto'].where((i) => i['start'] == false).toList();

    await _collectionMessaggi.doc(channel).set({
      'contenuto': _modifiedMessages,
      'lastUsedId': Constants.workflowId + 1
    });
  }

  //endregion

  //region Setters
  /// Permette di aggiungere un allievo a Firestore con i parametri specificati.
  static Future<void> addStudent(
      String sid,
      String tel,
      String nome,
      String cognome,
      String sezione,
      String ruolo,
      String nascita,
      String email) async {
    _collectionUtenti.doc(sid).set({
      'tel': tel,
      'nome': nome,
      'cognome': cognome,
      'annoScolastico': Constants.currentSchoolYear,
      'sezione': sezione,
      'ruolo': ruolo.toLowerCase(),
      'supervisionati': FieldValue.arrayUnion([]),
      'nascita': nascita,
      'email': email,
      'abilitato': true
    });
  }

  /// Permette di aggiungere un genitore a Firestore con i parametri
  /// specificati.
  static Future<void> addParent(
      String sid,
      String tel,
      String nome,
      String cognome,
      String ruolo,
      List<String> supervisionati,
      String nascita,
      String email) async {
    _collectionUtenti.doc(sid).set({
      'tel': tel,
      'nome': nome,
      'cognome': cognome,
      'annoScolastico': Constants.currentSchoolYear,
      'sezione': '',
      'ruolo': ruolo.toLowerCase(),
      'supervisionati': FieldValue.arrayUnion(supervisionati),
      'nascita': nascita,
      'email': email,
      'abilitato': true
    });
  }

  /// Permette di aggiungere un docente a Firestore con i parametri specificati.
  static Future<void> addTeacher(String sid, String tel, String nome,
      String cognome, String ruolo, String nascita, String email) async {
    _collectionUtenti.doc(sid).set({
      'tel': tel,
      'nome': nome,
      'cognome': cognome,
      'annoScolastico': Constants.currentSchoolYear,
      'sezione': '',
      'ruolo': ruolo.toLowerCase(),
      'supervisionati': FieldValue.arrayUnion([]),
      'nascita': nascita,
      'email': email,
      'abilitato': true
    });
  }

  /// Permette di aggiungere un messaggio al canale specificato.
  /// Il messaggio è una mappa che contiene le seguenti informazioi:
  /// il timestamp, il testo, l'SID dell'utente e, inoltre, durante l'esecuzione
  /// del metodo, verrà salvato anche il nome dell'utente.
  static Future<void> addMessage(
      String channel, Map<String, dynamic> messageInfo) async {
    String? username = (await getUsernameById(messageInfo["sid"]))! +
        (Constants.ruolo == "Contributore" ? " - " + Constants.sezione : "");
    messageInfo.addAll({"nome": username});
    _collectionMessaggi.doc(channel).update({
      "contenuto": FieldValue.arrayUnion([messageInfo])
    });
  }

  /// Aggiunge un nuovo elemento del workflow
  /// [workflowInfo] contiene le informazioni del workflow da aggiungere
  static Future<void> addWorkflow(
      String channel, Map<String, dynamic> workflowInfo) async {
    _collectionMessaggi.doc(channel).update({
      "contenuto": FieldValue.arrayUnion([workflowInfo])
    });
  }

  //endregion Setters

  //region Workflow
  /// Avvia la domanda iniziale generica per poi poter avviare i workflow collegati a quel canale.
  /// [channel] è il canale
  static Future<void> startWorkflow(String channel) async {
    await Database.saveLastUsedId(channel);

    var doc = await _collectionCanali.doc(channel).get();
    List workflow = List.from(doc['workflow']);

    var docMessages = await _collectionMessaggi.doc(channel).get();

    List messages = List.from(docMessages['contenuto']);

    if (messages.isEmpty || !messages.last['start']) {
      await Database.addWorkflow(channel, {
        "messaggio": "Cosa hai bisogno?",
        "nome": "App",
        "sid": Authenticate.firebaseAuth.currentUser!.uid,
        "creatoAlle": Timestamp.now(),
        "start": true,
        "workflow": workflow
      });
    }
  }

  /// Ritorna le domande di un workflow.
  /// [name] è il nome del workflow
  static Future<List> chooseWorkflow(String name) async {
    var doc = await _collectionWorkflow.doc(name).get();
    return List.from(doc['flow']);
  }

  /// Aggiunge una nuova azione al db.
  /// [channel] è il canale a cui aggiungere l'azione
  /// [position] numero dell'azione
  /// [workflowName] è il nome del workflow corrente
  /// [message] è il messaggio dell'azione
  /// [id] è l'id della conversazione
  /// [action] è opzionale e serve per sapere che tipologia di attesa bisogna seguire
  static Future<bool> addFlowToMessages(
      String channel, int position, String workflowName, String message, int id,
      {String action = "",
      String sid = "",
      String studenteUsername = ""}) async {
    bool action = true;
    List flow = await Database.chooseWorkflow(workflowName);
    if (position >= flow.length) {
      return false;
    }
    String token;
    flow.getRange(position, position + 1).forEach((line) async => {
          if (line['action'] == 'ask')
            {
              await Database.addWorkflow(channel, {
                "id": id,
                "type": "question",
                "input": line['input'],
                "sid": Authenticate.firebaseAuth.currentUser!.uid,
                "nome": (await getUsernameById(Authenticate
                        .firebaseAuth.currentUser?.uid as String))! +
                    " - " +
                    Constants.sezione,
                "creatoAlle": Timestamp.now(),
                "numeroDomanda": position,
                "start": false,
                "temporary": true,
                "messaggio": line['question'],
              }),
            }
          else if (flow[position]['action'].toString().startsWith("wait"))
            {
              print("database: " + studenteUsername),
              action = false,
              token = await Database.getTokenById(
                  Authenticate.firebaseAuth.currentUser!.uid) as String,
              Notifications.sendPushMessage(channel + " - Conferma",
                  line['question'] + " per " + studenteUsername,
                  token: token),
              action = false,
              await Database.addWorkflow(channel, {
                "id": id,
                "type": "wait",
                "input": line['input'],
                "sid": await Database.getWorkflowSid(id, channel),
                "nome": flow[position]['action'] == "waitparent"
                    ? await Database.getUsernameById(
                        await Database.getParentSID(
                                Authenticate.firebaseAuth.currentUser!.uid)
                            as String)
                    : "capolaboratorio",
                "creatoAlle": Timestamp.now(),
                "numeroDomanda": position,
                "options": line['options'],
                "start": false,
                "temporary": true,
                "messaggio":
                    line['question'] + " - " + (await getUsernameById(sid)),
                "waitingfor": flow[position]['action'] == "waitparent"
                    ? await Database.getParentSID(
                        Authenticate.firebaseAuth.currentUser!.uid)
                    : "capolaboratorio",
                "workflowName": workflowName,
                "action": flow[position]['action'].toString(),
              }),
            },
        });
    return action;
  }

  /// Modifica sul db i messaggi dei workflow di tipo wait registrando la risposta dell'utente.
  /// [channel] è il canale dove deve essere registrata la modifica
  /// [id] è l'id della conversazione
  /// [accepted] è lo stato della risposta
  static Future<void> replyToWorkflow(
      String channel, int id, bool accepted) async {
    List _modifiedMessages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    _modifiedMessages = doc['contenuto'].toList();
    _modifiedMessages.forEach((e) {
      if ((e['waitingfor'] == Authenticate.firebaseAuth.currentUser?.uid ||
              e['waitingfor'] == Constants.ruolo) &&
          e['id'] == id) {
        e['accepted'] = accepted;
        e['temporary'] = false;
      }
    });

    await _collectionMessaggi.doc(channel).set({
      'contenuto': _modifiedMessages,
      'lastUsedId': Constants.workflowId + 1
    });
  }

  /// Permette di salvare le risposte di un workflow inserite da un contributore.
  /// [channel] è il canale dove si trova il workflow
  static Future<void> saveWorkflowResponses(String channel) async {
    List messages = [];
    var doc = await _collectionMessaggi.doc(channel).get();
    messages = doc['contenuto'];
    var responses = messages
        .where(
            (i) => i['type'] == "response" && i['id'] == Constants.workflowId)
        .toList();

    Map<String, dynamic> responseInfo = <String, dynamic>{};
    responseInfo["messaggio"] = "";

    for (var value in responses) {
      responseInfo["messaggio"] = responseInfo["messaggio"].toString() +
          value['messaggio'] +
          ": " +
          value['response'] +
          " \n";
    }
    responseInfo['temporary'] = false;
    responseInfo['id'] = Constants.workflowId;
    responseInfo['start'] = false;
    responseInfo['creatoAlle'] = Timestamp.now();
    responseInfo['sid'] = Authenticate.firebaseAuth.currentUser?.uid;
    responseInfo['nome'] = (await getUsernameById(
            Authenticate.firebaseAuth.currentUser?.uid as String))! +
        " - " +
        Constants.sezione;
    await Database.addWorkflow(channel, responseInfo);
    await Database.removeTemporaryMessages(channel);
  }
//endregion Workflow
}
