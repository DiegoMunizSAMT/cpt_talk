import 'package:cpt_talk/templates/widgets.dart';
import 'package:flutter/material.dart';

/// La classe rappresenta una pagina che viene mostrata in caso di account disabilitato.
class AccountDisabled extends StatefulWidget {
  const AccountDisabled({Key? key}) : super(key: key);

  @override
  _AccountDisabledState createState() => _AccountDisabledState();
}

class _AccountDisabledState extends State<AccountDisabled> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainAppBarWithSignOut(context),
      body: const Center(
          child: Text(
              "Account disabilitato, per chiarimenti contattare l'amministratore")),
    );
  }
}
