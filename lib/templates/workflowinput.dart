import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helpers/database.dart';
import 'constants.dart';

/// La classe rappresenta un messaggio con input.
/// [input] varia il tipo di input che è possibile inserire, le opzioni sono "text", "date", "time".
/// [timestamp] è l'orario mostrato nel messaggio
/// [channel] è il canale dove aggiungere il messaggio
/// [numeroDomanda] è il numero della domanda del workflow
/// [messaggio] è la stringa che contiene il messaggio da mostrare
class WorkflowInput extends StatefulWidget {
  final String input;
  final Timestamp timestamp;
  final String channel;
  final int numeroDomanda;
  final String messaggio;

  const WorkflowInput(
      {Key? key,
      required this.input,
      required this.timestamp,
      required this.channel,
      required this.numeroDomanda,
      required this.messaggio})
      : super(key: key);

  @override
  State<WorkflowInput> createState() => _WorkflowInputState();
}

class _WorkflowInputState extends State<WorkflowInput> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  @override
  State<WorkflowInput> createState() => _WorkflowInputState();

  final DateTime _now = DateTime.now();
  bool _savingState = false;

  bool? inputenabled = true;
  String? input;
  DateTime? _data;
  TimeOfDay? _orario;

  @override
  Widget build(BuildContext context) {
    DateTime unformattedDate =
        DateTime.parse(widget.timestamp.toDate().toString());
    String date = DateFormat('dd/MM/yyyy, HH:mm').format(unformattedDate);

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 24),
      alignment: Alignment.centerRight,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: const EdgeInsets.only(left: 10),
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 20,
          ),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomLeft: Radius.circular(23),
                  bottomRight: Radius.zero),
              gradient: LinearGradient(
                colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Tu",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w400)),
              const SizedBox(
                height: 5,
              ),
              Text(widget.messaggio,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
              const SizedBox(
                height: 25,
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.input == "text") getInputText(widget.messaggio),
                    if (widget.input == "date") getInputDate(widget.messaggio),
                    if (widget.input == "time") getInputTime(widget.messaggio),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate will return true if the form is valid, or false if
                          // the form is invalid.
                          if (_formKey.currentState!.validate()) {
                            // Process data.
                            _formKey.currentState!.save();
                            setState(() {
                              inputenabled = false;
                            });
                            String studenteUsername = await Database.getUsernameById(Authenticate.firebaseAuth.currentUser?.uid as String) as String;
                            await Database.addWorkflow(widget.channel, {
                              "id": Constants.workflowId,
                              "type": "response",
                              "input": widget.input,
                              "response": input,
                              "temporary": true,
                              "start": false,
                              'messaggio': widget.messaggio,
                              "numeroDomanda": widget.numeroDomanda,
                            });
                            bool status = await Database.addFlowToMessages(
                                widget.channel,
                                widget.numeroDomanda + 1,
                                Constants.workflowName,
                                widget.messaggio,
                                Constants.workflowId,
                            sid: Authenticate.firebaseAuth.currentUser?.uid as String,
                            studenteUsername: studenteUsername);
                            if (!status) {
                              await Database.saveWorkflowResponses(
                                  widget.channel);
                            }
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
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

  Widget getInputText(String message) {
    return TextFormField(
      enabled: inputenabled,
      onSaved: (String? value) {
        input = value;
        setState() {
          inputenabled = false;
        }
      },
      decoration: InputDecoration(
        icon: const Icon(
          Icons.text_fields,
          color: Colors.white60,
        ),
        filled: true,
        fillColor: Colors.white60,
        labelText: message,
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
    );
  }

  Widget getInputDate(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextFormField(
            enabled: !_savingState,
            controller: dateController,
            readOnly: true,
            onSaved: (String? value) {
              input = value;
            },
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              filled: true,
              fillColor: Colors.white60,
              icon: const Icon(
                Icons.date_range_outlined,
                color: Colors.white60,
              ),
              labelText: message,
            ),
            validator: (val) {
              return val != null && val.isNotEmpty
                  ? null
                  : "Seleziona una data!";
            },
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        ElevatedButton(
          onPressed: _savingState ? null : () => _selectDate(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('Seleziona'),
          ),
        ),
      ],
    );
  }

  Widget getInputTime(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextFormField(
            enabled: !_savingState,
            controller: timeController,
            readOnly: true,
            onSaved: (String? value) {
              input = value;
              setState() {
                inputenabled = false;
              }
            },
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              filled: true,
              fillColor: Colors.white60,
              icon: const Icon(
                Icons.access_time_outlined,
                color: Colors.white60,
              ),
              labelText: message,
            ),
            validator: (val) {
              return val != null && val.isNotEmpty
                  ? null
                  : "Seleziona un orario!";
            },
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        ElevatedButton(
          onPressed: _savingState ? null : () => _selectTime(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('Seleziona'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        locale: Constants.appLocale,
        initialDate: _data ?? DateTime.now(),
        firstDate: DateTime(Constants.firstDateInput),
        lastDate: DateTime(Constants.lastDateInput),
        fieldHintText: 'gg/mm/aaaa');
    if (picked != null && picked != _now) {
      setState(() {
        _data = picked;
        dateController.text = DateFormat(Constants.dateFormat).format(_data!);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      initialTime: TimeOfDay.now(),
      context: context,
    );
    if (picked != null) {
      _orario = picked;
      setState(() {
        timeController.text = "${_orario!.hour}:${_orario!.minute}";
      });
    }
  }
}
