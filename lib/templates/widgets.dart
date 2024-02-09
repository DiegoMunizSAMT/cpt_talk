import 'package:cpt_talk/helpers/authenticate.dart';
import 'package:cpt_talk/helpers/simpledata.dart';
import 'package:cpt_talk/views/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Ritorna l'AppBar di default per CPT Talk.
AppBar mainAppBar() {
  return AppBar(
    title: const Text('CPT Talk'),
  );
}

/// Ritorna l'AppBar default di CPT Talk con la possibilità di effettuare il
/// logout.
AppBar mainAppBarWithSignOut(context) {
  return AppBar(
    title: const Text('CPT Talk'),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 15),
        child: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await Authenticate.firebaseAuth.signOut();
            await SimpleData.setLoginState(false);
            await SimpleData.setSID("");
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const SignIn()));
          },
        ),
      )
    ],
  );
}

/// Ritorna l'AppBar di default di CPT Talk per la schermata di un canale.
AppBar chatAppBar(context, String title) {
  return AppBar(
    title: Text(title),
  );
}

/// Ritorna un semplice dialogo di informazione, con title e body specificati
/// da parametro.
Future infoDialog(context, String title, String body) {
  return showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Chiudi'),
              )
            ],
          ));
}

/// Permette di avviare un caricamento, con lo status specificato da parametro.
Future<void> loading(String status) async {
  await EasyLoading.show(
    status: status,
  );
}

/// Se presente, permette di terminare un caricamento.
Future<void> endLoading() async {
  EasyLoading.isShow ? EasyLoading.dismiss() : null;
}

/// Stateful widget che permette di rappresentare un nuovo TextFormField
/// per i campi di testo di password. Oscura il testo con '*' e permette di
/// renderlo visible tramite un'icona a forma di occhio.
/// I parametri da inserire sono opzionali, proprio come un TextFormField.
class PasswordField extends StatefulWidget {
  const PasswordField(
      {this.enabled,
      this.fieldKey,
      this.hintText,
      this.labelText,
      this.helperText,
      this.errorText,
      this.onSaved,
      this.validator,
      this.onFieldSubmitted});

  final bool? enabled;
  final Key? fieldKey;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      enabled: widget.enabled,
      obscureText: _obscureText,
      maxLength: 48,
      onSaved: widget.onSaved,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          filled: true,
          hintText: widget.hintText,
          labelText: widget.labelText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          icon: const Icon(Icons.password_outlined),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            child: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          )),
    );
  }
}
