import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CastList extends ChangeNotifier {
  List<String> _l = [];

  CastList() {
    this.update();
  }

  List<String> get l => this._l;

  Future<void> update() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    this._l = appDocDir.listSync().map((e) => e.path).toList();
    notifyListeners();
  }
}
