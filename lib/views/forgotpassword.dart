import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:cpt_talk/templates/constants.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  bool _sendingState = false;

  String? _email;

  /// Permette di inviare una email di reimpostazione password al destinatario
  /// stabilito. Questo metodo sfrutta un metodo già predisposto dalla classe
  /// FirebaseAuth, creato dagli sviluppatori di Firebase.
  sendForgotPasswordEmail() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        String? authError;
        await Authenticate.firebaseAuth
            .sendPasswordResetEmail(email: _email!)
            .onError((error, stackTrace) {
          (error) as FirebaseAuthException;
          authError = error.code;
        });

        if (authError != null) throw FirebaseAuthException(code: authError!);

        await endLoading();

        infoDialog(context, 'Reimpostazione password',
                'È stata inviata una e-mail all\'indirizzo $_email. \nSi prega di seguirne le istruzioni per reimpostare la password.')
            .then((value) {
          Navigator.pop(context);
        });
      } on FirebaseAuthException catch (e) {
        await endLoading();
        if (e.code == 'user-not-found') {
          infoDialog(context, 'Errore - Utente non trovato',
              'Non è stato trovato nessun utente associato all\'indirizzo $_email.');
        }
      }
    }

    await endLoading();

    setState(() {
      _sendingState = !_sendingState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: mainAppBar(),
        body: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    'Inserisci l\'indirizzo e-mail al quale vuoi reimpostare la password.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          enabled: !_sendingState,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            filled: true,
                            icon: Icon(Icons.email),
                            hintText: 'Inserisci la tua e-mail',
                            labelText: 'E-mail',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (String? value) {
                            _email = value;
                          },
                          validator: (val) {
                            return val != null &&
                                    RegExp(Constants.emailRegex).hasMatch(val)
                                ? null
                                : "Inserisci una e-mail valida!";
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      ElevatedButton(
                        onPressed: _sendingState
                            ? null
                            : () async {
                                setState(() {
                                  _sendingState = !_sendingState;
                                });
                                await loading('Invio e-mail in corso...');
                                sendForgotPasswordEmail();
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text('Invia'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
