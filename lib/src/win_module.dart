import 'dart:io';

import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

import 'module.dart';

class WinModule {
  String output = "dist/";
  String target = "exe";
  String changelog = "";
  Pubspec? _pubspec;

  Pubspec get pubspec {
    if (_pubspec == null) {
      final yamlString = File('pubspec.yaml').readAsStringSync();
      _pubspec = Pubspec.parse(yamlString);
    }
    return _pubspec!;
  }

  List<Module> modules = [];

  WinModule() {
    readYaml();
  }

  void readYaml() {
    var modulesYaml = File("modules.yaml");
    if (!modulesYaml.existsSync()) {
      return;
    }
    var moduleYaml = loadYaml(modulesYaml.readAsStringSync());
    target = moduleYaml["target"] ?? "exe";
    output = moduleYaml["output"] ?? "dist/";
    changelog = moduleYaml["changelog"] ?? "";
    if (moduleYaml["modules"] != null) {
      var modulesJson = moduleYaml["modules"] as List<dynamic>;
      modulesJson.forEach((element) {
        modules.add(Module(element["name"], element["path"]));
      });
    }
  }

  /// 更新Runner.rc版本号，与pubspec一致
  updateVersion() async {
    var major = pubspec.version!.major;
    var minor = pubspec.version!.minor;
    var patch = pubspec.version!.patch;
    var runnerFile = File("windows/runner/Runner.rc");
    var versionNumberReg = RegExp(r'VERSION_AS_NUMBER \d+,\d+,\d+');
    var versionStringReg = RegExp(r'VERSION_AS_STRING "\d+.\d+.\d+"');
    var runnerStr = runnerFile.readAsStringSync();
    runnerStr = runnerStr.replaceFirst(
        versionNumberReg, "VERSION_AS_NUMBER $major,$minor,$patch");
    runnerStr = runnerStr.replaceFirst(
        versionStringReg, 'VERSION_AS_STRING "$major.$minor.$patch"');

    runnerFile.writeAsStringSync(runnerStr);
  }

  String getArtifactName() {
    return "${pubspec.name.pascalCase}-${getVersionString()}.$target";
  }

  String getVersionString() {
    return "${pubspec.version!.major}.${pubspec.version!.minor}.${pubspec.version!.patch}";
  }

  String? getBuildCode() {
    return pubspec.version!.build.isEmpty
        ? null
        : pubspec.version!.build.first.toString();
  }
}
