import 'dart:math';

import 'package:cpt_talk/helpers/database.dart';
import 'package:cpt_talk/templates/constants.dart';
import 'package:cpt_talk/templates/widgets.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phone_form_field/phone_form_field.dart';

class EditUser extends StatefulWidget {
  const EditUser({Key? key}) : super(key: key);

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  final _formKey = GlobalKey<FormState>();
  bool _savingState = false;
  final DateTime _now = DateTime.now();

  TextEditingController dateController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _sectionFocusNode = FocusNode();

  String? _nome;
  String? _cognome;
  String? _sezione;
  String? _numeroTel;
  DateTime? _nascita;
  String? _email;
  List<String> children = [];

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
    _sectionFocusNode.addListener(_onSectionFocusChanged);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _sectionFocusNode.removeListener(_onSectionFocusChanged);
    _phoneFocusNode.dispose();
    _sectionFocusNode.dispose();

    super.dispose();
  }

  /// Metodo listener che viene invocato quando avviene un cambio di focus
  /// al campo di scelta del numero di telefono.
  void _onPhoneFocusChanged() {
    setState(() {});
  }

  /// Metodo listener che viene invocato quando avviene un cambio di focus
  /// al campo di scelta della sezione.
  void _onSectionFocusChanged() {
    setState(() {});
  }

  /// Questo metodo avvia la procedura di richiesta dell'inserimento dei numeri
  /// di telefono dei figli.
  /// Questo metodo ha come parametri:
  /// - counter: numero di figli aggiunti (inizialmente 0)
  /// - (optional) returnToSummary: indica se fare apparire il bottone per
  ///   visualizzare il sommario dei figli.
  /// Questa procedura consiste in una serie di dialoghi in successione, in base
  /// alla scelta dell'utente. Non possono essere inseriti duplicati (stessi
  /// figli 2 volte).
  Future<void> _startChildrenPhoneRequest(BuildContext context, int counter,
      [bool? returnToSummary]) async {
    var childrenFormKey = GlobalKey<FormState>();
    String? child;
    String phoneNumber = '';
    bool registered = false;
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Inserisci numero del figlio'),
            content: Form(
              key: childrenFormKey,
              child: PhoneFormField(
                decoration: const InputDecoration(
                  labelText: 'Numero del figlio',
                ),
                defaultCountry: Constants.initialCountryCode,
                countrySelectorNavigator:
                    const CountrySelectorNavigator.dialog(),
                onSaved: (phone) async {
                  phoneNumber = phone!.international;
                },
                validator: (phone) {
                  return phone != null && phone.validate()
                      ? null
                      : "Inserisci un numero di telefono valido!";
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'Esci');
                },
                child: const Text('Esci'),
              ),
              if (returnToSummary != null && returnToSummary)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'Sommario');
                  },
                  child: const Text('Sommario'),
                ),
              TextButton(
                onPressed: () async {
                  if (childrenFormKey.currentState!.validate()) {
                    childrenFormKey.currentState!.save();
                    child = await Database.getChildSID(phoneNumber);
                    registered = child != null && !children.contains(child)
                        ? true
                        : false;
                    registered ? children.add(child!) : null;
                    Navigator.pop(context, 'Aggiungi');
                  }
                },
                child: const Text('Aggiungi'),
              )
            ],
          );
        }).then((value) async {
      if (value == 'Esci') {
        children = [];
        return;
      }
      if (value == 'Sommario') {
        await _showChildrenSummary(context, counter);
        return;
      }
      registered
          ? await showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Successo'),
                  content: counter < Constants.maxChildrenCount
                      ? const Text(
                          'Il figlio è stato registrato con successo. Vuoi registrare un altro figlio?')
                      : const Text(
                          'Il figlio è stato registrato con successo.'),
                  actions: <Widget>[
                    if (counter < Constants.maxChildrenCount)
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context, 'Sì');
                        },
                        child: const Text('Sì'),
                      ),
                    if (counter < Constants.maxChildrenCount)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'No');
                        },
                        child: const Text('No'),
                      ),
                    if (counter >= Constants.maxChildrenCount)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'Sommario');
                        },
                        child: const Text('Sommario'),
                      )
                  ],
                );
              },
            ).then((value) async {
              if (value == 'Sì') {
                await _startChildrenPhoneRequest(context, ++counter, true);
                return;
              } else {
                await _showChildrenSummary(context, counter);
                return;
              }
            })
          : await infoDialog(
                  context,
                  !children.contains(child) ? 'Errore' : 'Attenzione',
                  !children.contains(child)
                      ? 'Nessun figlio è registrato con il numero di telefono:\n$phoneNumber'
                      : 'Questo figlio è già stato aggiunto alla tua lista di figli:\n\n$phoneNumber')
              .then((value) async {
              await _startChildrenPhoneRequest(
                  context, counter, returnToSummary);
              return;
            });
    });
  }

  /// Mostra il sommario dei figli scelti.
  /// Il metodo prende come parametro il numero di figli aggiunti.
  Future<void> _showChildrenSummary(context, int counter) async {
    List<Map<String, String>> summary =
        await Database.getChildrenSummary(children);
    String content = "Vuoi registrare i seguenti figli?\n\n";

    for (var child in summary) {
      content += child['child']! + ": " + child['phoneNumber']! + "\n";
    }

    content += "\nScegli come proseguire.";

    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sommario'),
            content: Text(content),
            actions: <Widget>[
              if (counter < Constants.maxChildrenCount)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'Altri');
                  },
                  child: const Text('Aggiungi altri'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'No');
                },
                child: const Text('No, ripetere'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, 'Sì');
                },
                child: const Text('Sì, procedere'),
              )
            ],
          );
        }).then((value) async {
      if (value == 'No') {
        children = [];
        await _startChildrenPhoneRequest(context, 0);
        return;
      } else if (value == 'Altri') {
        await _startChildrenPhoneRequest(context, counter, true);
        return;
      }
    });
  }

  /// Permette di aprire il datePicker di Google. Utile per selezionare la data
  /// di nascita dell'utente.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        locale: Constants.appLocale,
        initialDate: _nascita ?? DateTime(Constants.initialDate),
        firstDate: DateTime(_now.year - Constants.firstDate),
        lastDate: DateTime(_now.year - Constants.lastDate),
        fieldHintText: 'gg/mm/aaaa');
    if (picked != null && picked != _now) {
      setState(() {
        _nascita = picked;
        dateController.text =
            DateFormat(Constants.dateFormat).format(_nascita!);
      });
    }
  }

  /// WIP
  editUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await loading('Modifica in corso...');

      infoDialog(
          context,
          "DEBUG",
          "Nome: " +
              (_nome ?? Constants.nome) +
              "\nCognome: " +
              (_cognome ?? Constants.cognome) +
              "\nNumero di telefono: " +
              (_numeroTel ?? Constants.numeroTel) +
              "\nData di nascita: " +
              (dateController.text == ""
                  ? Constants.nascita
                  : dateController.text) +
              "\nClasse: " +
              (_sezione ?? Constants.sezione) +
              "\nE-mail: " +
              (_email ?? Constants.email));

      try {
        Constants.nome = _nome!;
        Constants.cognome = _cognome!;
        Constants.numeroTel = _numeroTel!;
        Constants.nascita = dateController.text;
        Constants.sezione = _sezione!;
        Constants.email = _email!;
      } on FirebaseAuthException catch (e) {
        await endLoading();
        infoDialog(context, 'Errore - Modifica fallita',
            'C’è stato un errore durante la modifica dell’utente.');
      }

      await endLoading();
    }

    setState(() {
      _savingState = !_savingState;
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
                  'Modifica utente',
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
                      enabled: !_savingState,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        filled: true,
                        icon: Icon(Icons.person_outline),
                        hintText: 'Inserisci il tuo nome',
                        labelText: 'Nome',
                      ),
                      keyboardType: TextInputType.name,
                      controller: TextEditingController(
                          text: (_nome ?? Constants.nome)),
                      onSaved: (String? value) {
                        _nome = value;
                      },
                      validator: (val) {
                        return val != null && val.isNotEmpty
                            ? null
                            : "Inserisci un nome!";
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      enabled: !_savingState,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        filled: true,
                        icon: Icon(Icons.people_alt_outlined),
                        hintText: 'Inserisci il tuo cognome',
                        labelText: 'Cognome',
                      ),
                      keyboardType: TextInputType.name,
                      controller: TextEditingController(
                          text: (_cognome ?? Constants.cognome)),
                      onSaved: (String? value) {
                        _cognome = value;
                      },
                      validator: (val) {
                        return val != null && val.isNotEmpty
                            ? null
                            : "Inserisci un cognome!";
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android_outlined,
                          color: !_phoneFocusNode.hasFocus
                              ? const Color(0xFF898989)
                              : Colors.red,
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: PhoneFormField(
                            enabled: !_savingState,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              filled: true,
                              hintText: 'Inserisci il tuo numero di telefono',
                              labelText: 'Numero di telefono',
                            ),
                            defaultCountry: Constants.initialCountryCode,
                            initialValue: PhoneNumber.fromRaw(
                                (_numeroTel ?? Constants.numeroTel)),
                            autovalidateMode: AutovalidateMode.disabled,
                            focusNode: _phoneFocusNode,
                            onChanged: (phone) {
                              _numeroTel = phone?.international;
                            },
                            validator: (phone) {
                              return phone != null && phone.validate()
                                  ? null
                                  : "Inserisci un numero di telefono valido!";
                            },
                          ),
                        ),
                      ],
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
                            enabled: !_savingState,
                            controller: TextEditingController(
                                text: _nascita == null
                                    ? Constants.nascita
                                    : DateFormat(Constants.dateFormat)
                                        .format(_nascita!)),
                            readOnly: true,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              filled: true,
                              icon: Icon(Icons.date_range_outlined),
                              hintText: 'Seleziona la tua data di nascita',
                              labelText: 'Data di nascita',
                            ),
                            validator: (val) {
                              return val != null && val.isNotEmpty
                                  ? null
                                  : "Seleziona una data di nascita!";
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        ElevatedButton(
                          onPressed:
                              _savingState ? null : () => _selectDate(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text('Seleziona'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    DropdownSearch<String>(
                      enabled: !_savingState,
                      selectedItem: (_sezione ?? Constants.sezione),
                      dropdownSearchDecoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        filled: true,
                        icon: Icon(Icons.house_outlined),
                        hintText: 'Seleziona la tua classe',
                        labelText: 'Classe',
                      ),
                      mode: Mode.DIALOG,
                      items: Database.classi,
                      showSearchBox: true,
                      onChanged: (val) {
                        _sezione = val;
                      },
                      validator: (val) {
                        return val != null ? null : "Seleziona una sezione!";
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      enabled: !_savingState,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        filled: true,
                        icon: Icon(Icons.email_outlined),
                        hintText: 'Inserisci la tua e-mail',
                        labelText: 'E-mail',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      controller: TextEditingController(
                          text: (_email ?? Constants.email)),
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
                    const SizedBox(
                      height: 24,
                    ),
                    ElevatedButton(
                      onPressed: _savingState
                          ? null
                          : () async {
                              setState(() {
                                _savingState = !_savingState;
                              });
                              editUser();
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Modifica'),
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
