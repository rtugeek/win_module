import 'dart:io';

import 'package:pubspec_parse/pubspec_parse.dart';

class Utils{


  static Pubspec getPubspec() {
    Directory current = Directory.current;
    File pubspecFile = File("${current.path}/pubspec.yaml");
    var pubspecStr = pubspecFile.readAsStringSync();
    var pubspec = Pubspec.parse(pubspecStr);
    return pubspec;
  }
}