import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:cpt_talk/helpers/simpledata.dart';
import 'package:cpt_talk/templates/constants.dart';
import 'package:cpt_talk/views/forgotpassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:cpt_talk/views/signup.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

import 'chatroom.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  bool _loggingState = false;

  bool _emailVerified = true;
  bool _userExists = true;
  bool _correctPassword = true;
  String? _email;
  String? _password;
  bool _internetConnection = false;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();

    // Add your code here
    checkAuthenticationMethods();
  }

  Future<void> checkAuthenticationMethods() async {
    // Is not running on the web
    if (!kIsWeb) {
      bool canAuthenticate = await auth.isDeviceSupported();
      bool hasBiometrics = await auth.canCheckBiometrics;

      List<BiometricType> availableBiometrics = [];
      if (hasBiometrics)
        availableBiometrics = await auth.getAvailableBiometrics();

      print('Device Support for Authentication: $canAuthenticate');
      print('Device has Biometric Capabilities: $hasBiometrics');
      print('Available Biometrics: $availableBiometrics');

      // Check for PIN/Pattern/Password
      bool hasPinOrPatternOrPassword = (canAuthenticate && !hasBiometrics);
      print('Device has PIN/Pattern/Password: $hasPinOrPatternOrPassword');

      // Authenticate the user
      try {
        final bool didAuthenticate =
            await auth.authenticate(localizedReason: 'Please authenticate');

        if (didAuthenticate) {
          //Something
        }
      } on PlatformException catch (e) {
        print('Exception: $e');
      }
    } else {
      print('Device Support for Authentication: false');
    }
  }

  /// Il metodo permette di autenticare l'utente con la email e la password.
  signIn() async {
    if (!kIsWeb) {
      if (!(await InternetConnectionChecker().hasConnection)) {
        await endLoading();
        setState(() {
          _internetConnection = true;
        });
      }
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await Authenticate.firebaseAuth
            .signInWithEmailAndPassword(email: _email!, password: _password!);

        User? user = Authenticate.firebaseAuth.currentUser;

        if (user != null && !user.emailVerified) {
          await endLoading();
          setState(() {
            _emailVerified = false;
            _userExists = true;
            _correctPassword = true;
          });
        } else {
          await endLoading();
          await SimpleData.setLoginState(true);
          await SimpleData.setSID(user!.uid);

          // scarico le informazioni su ruolo, sezione, email, etc dell'utente autenticato
          DocumentReference documentReference = FirebaseFirestore.instance
              .collection(Constants.collectionUtenti)
              .doc(Authenticate.firebaseAuth.currentUser!.uid);
          Constants.nome = await documentReference.get().then((value) {
            return value.get("nome");
          });
          Constants.cognome = await documentReference.get().then((value) {
            return value.get("cognome");
          });
          Constants.numeroTel = await documentReference.get().then((value) {
            return value.get("tel");
          });
          Constants.nascita = await documentReference.get().then((value) {
            return value.get("nascita");
          });
          Constants.sezione = await documentReference.get().then((value) {
            return value.get("sezione");
          });
          Constants.email = await documentReference.get().then((value) {
            return value.get("email");
          });

          Constants.ruolo = await documentReference.get().then((value) {
            return value.get("ruolo");
          });

          Constants.abilitato = await documentReference.get().then((value) {
            return value.get("abilitato");
          });

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const ChatRoom()));
        }
      } on FirebaseAuthException catch (e) {
        await endLoading();
        if (e.code == 'user-not-found') {
          setState(() {
            _emailVerified = true;
            _userExists = false;
            _correctPassword = true;
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            _emailVerified = true;
            _userExists = true;
            _correctPassword = false;
          });
        }
      }
    }

    await endLoading();
    setState(() {
      _loggingState = !_loggingState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Sign In',
                  style: TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      enabled: !_loggingState,
                      decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          filled: true,
                          icon: const Icon(Icons.email),
                          hintText: 'Inserisci la tua e-mail',
                          labelText: 'E-mail',
                          errorText: !_emailVerified
                              ? 'E-mail non verificata: verifica la tua e-mail.'
                              : !_userExists
                                  ? 'Nessun utente è associato a questa e-mail.'
                                  : null),
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
                    const SizedBox(
                      height: 24,
                    ),
                    PasswordField(
                      enabled: !_loggingState,
                      labelText: 'Password',
                      errorText: _correctPassword
                          ? null
                          : 'La password inserita non è corretta.',
                      onSaved: (String? value) {
                        _password = value;
                      },
                      validator: (val) {
                        return val != null && val.length > 6
                            ? null
                            : "Inserisci una password valida! (minimo 6 caratteri)";
                      },
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(left: 40),
                      child: TextButton(
                        onPressed: _loggingState
                            ? null
                            : () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPassword()));
                              },
                        child: const Text('Password dimenticata?'),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    ElevatedButton(
                      onPressed: _loggingState
                          ? null
                          : () async {
                              setState(() {
                                _loggingState = !_loggingState;
                              });
                              await loading('Autenticazione in corso...');
                              signIn();
                            },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: const Text('Accedi'),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    _internetConnection
                        ? const Text(
                            "Connessione internet assente, verificare la propria connessione. Se il problema sussiste contattare l'amministratore di rete.",
                            style: TextStyle(color: Colors.red),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(
                      height: 24,
                    ),
                    Column(
                      children: [
                        const Text(
                            'Non hai un account? Scegli come registrarti!'),
                        const SizedBox(
                          height: 8,
                        ),
                        TextButton(
                          onPressed: _loggingState
                              ? null
                              : () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const SignUp(
                                                role: NewUserRole.Contributore,
                                              )));
                                },
                          child: const Text('Allievo'),
                        ),
                        TextButton(
                          onPressed: _loggingState
                              ? null
                              : () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const SignUp(
                                                role: NewUserRole.Docente,
                                              )));
                                },
                          child: const Text('Docente'),
                        ),
                        TextButton(
                          onPressed: _loggingState
                              ? null
                              : () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const SignUp(
                                                role: NewUserRole.Supervisore,
                                              )));
                                },
                          child: const Text('Genitore'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
