import 'package:cpt_talk/templates/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleData {
  //region Setters
  /// Imposta una shared preference per stabilire se un utente è loggato o no.
  static Future<void> setLoginState(bool loggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.loginStateKey, loggedIn);
  }

  /// Imposta una shared preference con il SID dell'utente loggato.
  static Future<void> setSID(String sid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sidKey, sid);
  }

  //endregion

  //region Getters
  /// Ritorna il valore della shared preference che indica se un utente è
  /// loggato oppure no.
  static Future<bool?> getLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.loginStateKey);
  }

  /// Ritorna il valore della shared preference con il SID dell'utente loggato.
  static Future<String?> getSID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.sidKey);
  }
//endregion
}
