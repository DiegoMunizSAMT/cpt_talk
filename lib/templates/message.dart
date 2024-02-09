import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Rappresenta un elemento della lista di messaggi, ovvero un messaggio,
/// caratterizzato dal testo del messaggio, dal nome dell'utente e dall'ora.
/// Se il messaggio è stato inviato dall'utente stesso, verrà disposto sulla
/// destra con un tipo di stile diverso da quelli disposti a sinistra (inviati
/// dagli altri utenti), oltre ad avere il nome "Tu".
class Message extends StatefulWidget {
  final String message;
  final String username;
  final bool sentByMe;
  final Timestamp timestamp;

  const Message({
    Key? key,
    required this.message,
    required this.username,
    required this.sentByMe,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
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
}
