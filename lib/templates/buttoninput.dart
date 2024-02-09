import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helpers/authenticate.dart';
import '../helpers/database.dart';
import '../helpers/notifications.dart';

/// La classe rappresenta un messaggio per l'approvazione da parte di supervisori o capolaboratorio.
/// [message] è la stringa che contiene il messaggio da mostrare
/// [buttons] è una lista
/// [timestamp] è l'orario mostrato nel messaggio
/// [username] è il nome da visualizzare nel messaggio
/// [channel] è il canale dove aggiungere il messaggio
/// [workflowposition] è il numero della domanda del workflow
/// [sentByMe] se il messaggio appartiene all'utente corrente
/// [accepted] se il workflow è stato accettato
/// [id] è l'id del workflow corrente
/// [numeroDomanda] è il numero della domanda del workflow
/// [workflowName] è il nome del workflow corrente
/// [sid] è il sid del supervisore dello studente che ha avviato il workflow
/// [studentSid] è il sid dello studente che ha avviato il workflow
class ButtonInput extends StatefulWidget {
  final String message;
  final List<String> buttons;
  final Timestamp timestamp;
  final String username;
  final String channel;
  final int workflowposition;
  final bool sentByMe;
  final int accepted;
  final int id;
  final int numeroDomanda;
  final String workflowName;
  final String sid;
  final String studentSid;

  const ButtonInput(
      {Key? key,
      required this.message,
      required this.buttons,
      required this.timestamp,
      required this.username,
      required this.sentByMe,
      required this.channel,
      required this.workflowposition,
      required this.accepted,
      required this.id,
      required this.numeroDomanda,
      required this.workflowName,
      required this.sid,
      required this.studentSid})
      : super(key: key);

  @override
  State<ButtonInput> createState() => _ButtonInputState();
}

class _ButtonInputState extends State<ButtonInput> {
  final int workflowState = 0;

  @override
  Widget build(BuildContext context) {
    DateTime unformattedDate =
        DateTime.parse(widget.timestamp.toDate().toString());
    String date = DateFormat('dd/MM/yyyy, HH:mm').format(unformattedDate);

    return Container(
      padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: widget.sentByMe ? 0 : 24,
          right: widget.sentByMe ? 24 : 0),
      alignment: widget.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: widget.sentByMe
              ? const EdgeInsets.only(left: 10)
              : const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(23),
                  topRight: const Radius.circular(23),
                  bottomLeft:
                      widget.sentByMe ? const Radius.circular(23) : Radius.zero,
                  bottomRight: widget.sentByMe
                      ? Radius.zero
                      : const Radius.circular(23)),
              gradient: LinearGradient(
                colors: widget.sentByMe
                    ? [const Color(0xFFEB3349), const Color(0xFFF45C43)]
                    : [const Color(0xFF7D7D7D), const Color(0xFF9E9E9E)],
              )),
          child: Column(
            crossAxisAlignment: widget.sentByMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(widget.sentByMe ? 'Tu' : widget.username,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w400)),
              const SizedBox(
                height: 5,
              ),
              Text(widget.message,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: widget.accepted == -1
                    ? _actionButtonsList()
                    : [
                        Text(widget.accepted == 1 ? "ACCETTATO" : "RIFIUTATO",
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                      ],
              ),
              const SizedBox(
                height: 5,
              ),
              Text(date,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w200)),
            ],
          )),
    );
  }

  List<ElevatedButton> actionButtons = [];
  List flow = [];

  /// Il metodo crea dinamicamente i bottoni in base al workflow
  List<Widget> _actionButtonsList() {
    for (int i = 0; i < widget.buttons.length; i++) {
      actionButtons.add(ElevatedButton(
        onPressed: !widget.sentByMe
            ? null
            : () async {
                await Database.replyToWorkflow(
                    widget.channel, widget.id, widget.buttons[i] == "ACCETTA");
                if (widget.buttons[i] == "ACCETTA") {
                  String studenteUsername = await Database.getUsernameById(widget.studentSid) as String;
                  print("buttoninout: " + studenteUsername);
                  await Database.addFlowToMessages(
                    widget.channel,
                    widget.numeroDomanda + 1,
                    widget.workflowName,
                    widget.message,
                    widget.id,
                    studenteUsername: studenteUsername,
                    sid: widget.studentSid,
                  );
                }

                /// Notifica allo studente
                String token =
                    await Database.getTokenById(widget.studentSid) as String;
                String username = await Database.getUsernameById(
                        Authenticate.firebaseAuth.currentUser?.uid as String)
                    as String;
                Notifications.sendPushMessage(
                    widget.channel + " - Risposta",
                    "La richiesta è stata " +
                        (widget.buttons[i] == "ACCETTA"
                            ? "accettata"
                            : "rifiutata") +
                        " da " +
                        username,
                    token: token);
              },
        child: Text(widget.buttons[i]),
      ));
    }
    return actionButtons;
  }
}
