import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helpers/database.dart';
import 'constants.dart';

/// La classe rappresenta il messaggio iniziale di ogni workflow.
/// [message] è la stringa che contiene il messaggio da mostrare
/// [workflows] è una lista che contiene tutti i workflow disponibili per quel canale
/// [timestamp] è l'orario mostrato nel messaggio
/// [start] deve essere a true per poter mostrare i workflows
/// [nome] è il nome da visualizzare nel messaggio
/// [channel] è il canale dove aggiungere il messaggio
/// [workflowposition] è il numero della domanda del workflow
class Workflow extends StatefulWidget {
  final String message;
  final List<String> workflows;
  final Timestamp timestamp;
  final bool start;
  final String nome;
  final String channel;
  final int workflowposition;

  const Workflow(
      {Key? key,
      required this.message,
      required this.workflows,
      required this.timestamp,
      required this.start,
      required this.nome,
      required this.channel,
      required this.workflowposition})
      : super(key: key);

  @override
  State<Workflow> createState() => _WorkflowState();
}

class _WorkflowState extends State<Workflow> {
  final int workflowState = 0;

  @override
  Widget build(BuildContext context) {
    DateTime unformattedDate =
        DateTime.parse(widget.timestamp.toDate().toString());
    String date = DateFormat('dd/MM/yyyy, HH:mm').format(unformattedDate);

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 24),
      alignment: Alignment.centerLeft,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 20,
          ),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.circular(23)),
              gradient: LinearGradient(
                colors: [Color(0xFF7D7D7D), Color(0xFF9E9E9E)],
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nome,
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
                children: widget.start ? _actionButtonsList() : [],
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

  List<Widget> _actionButtonsList() {
    for (int i = 0; i < widget.workflows.length; i++) {
      actionButtons.add(ElevatedButton(
        onPressed: () async {
          Database.removeFirstMessages(widget.channel);
          Constants.workflowName = widget.workflows[i];
          await Database.addFlowToMessages(
              widget.channel,
              widget.workflowposition,
              widget.workflows[i],
              widget.message,
              Constants.workflowId);
        },
        child: Text(widget.workflows[i]),
      ));
    }
    return actionButtons;
  }
}
