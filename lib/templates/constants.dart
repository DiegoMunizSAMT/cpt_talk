import 'dart:ui';

/// Enumerativo che comprende solo i ruoli possibli durante la registrazione.
enum NewUserRole { Contributore, Supervisore, Docente }

class Constants {
  //region FontFamily
  static const String ubuntuFontFamily = 'Ubuntu';

  //endregion

  //region Shared Preferences
  static const String loginStateKey = "loginState";
  static const String sidKey = "SID";

  //endregion

  //region App language
  static const Locale appLocale = Locale('it');

  //endregion

  //region Regex
  static const String emailRegex =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";

  //endregion

  //region CPT Settings
  static const String currentSchoolYear = '2021-2022';
  static const int maxChildrenCount = 5;

  //endregion

  //region DatePicker settings
  static const int initialDate = 2003;
  static const int firstDateInput = 2020;
  static const int lastDateInput = 2025;
  static const int firstDate = 70;
  static const int lastDate = 14;
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'hh:mm';

  //endregion

  //region PhoneNumber Settings
  static const String initialCountryCode = 'CH';

  //endregion

  //region Channels
  static const String channelDescription = 'descrizione';
  static const String channelRoleFilter = 'filtroRuoli';
  static const String channelConfidentiality = 'confidenzialità';

  //endregion

  //region Collections
  static const String collectionCanali = 'canali';
  static const String collectionUtenti = 'utenti';
  static const String collectionSezioni = 'sezioni';
  static const String collectionRuoli = 'ruoli';
  static const String collectionParametri = 'parametri';
  static const String collectionMessaggi = 'messaggi';
  static const String collectionWorkflow = 'workflow';
  static const String collectionAssociazioniCanali = 'associazioni_canali';

  //endregion

  //region Documents
  static const String documentParametriDocenti = 'docenti';

  //endregion

  //region Roles
  static const List<String> roles = [
    'amministratore',
    'superuser',
    'contributore',
    'contributore+',
    'supervisore',
    'docente',
    'capolaboratorio',
    'solaLettura'
  ];

//endregion
//region Helpers
  static String nome = 'nothing';
  static String cognome = 'nothing';
  static String numeroTel = '+410000000';
  static String nascita = 'nothing';
  static String sezione = 'nothing';
  static String email = 'nothing';

  static String ruolo = 'user';
  static bool abilitato = false;
  static String workflowName = 'nothing';
  static String? parentSid = "sid";
  static int workflowId = -1;
//endregion
}
