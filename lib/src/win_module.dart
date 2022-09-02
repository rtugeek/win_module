import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import 'package:win_module/src/job.dart';
import 'package:yaml/yaml.dart';

import 'module.dart';

class WinModule {
  String output = "dist/";
  Pubspec? _pubspec;
  Map<String, Job> jobs = {};

  Pubspec get pubspec {
    if (_pubspec == null) {
      final yamlString = File('pubspec.yaml').readAsStringSync();
      _pubspec = Pubspec.parse(yamlString);
    }
    return _pubspec!;
  }

  List<Module> modules = [];

  WinModule() {
    readBuildJson();
  }

  void readBuildJson() {
    var buildJson = File("build.json");
    if (!buildJson.existsSync()) {
      return;
    }
    var json = jsonDecode(buildJson.readAsStringSync());
    var jobs = json["jobs"] as Map<String, dynamic>;
    if (jobs.isNotEmpty) {
      jobs.forEach((key, value) {
        print("Job:$key found");
        var job = Job.fromJson(value);
        job.versionName = getVersionName();
        job.versionCode = getVersionCode() ?? "";
        job.projectName = pubspec.name;
        this.jobs[key] = job;
      });
    }
    output = json["output"] ?? "dist/";
    if (json["modules"] != null) {
      var modulesJson = json["modules"] as List<dynamic>;
      modulesJson.forEach((element) {
        modules.add(Module(element["name"], element["path"], element["build"]));
      });
    }
  }

  /// 更新Runner.rc版本号，与pubspec一致
  updateVersion() async {
    var major = pubspec.version!.major;
    var minor = pubspec.version!.minor;
    var patch = pubspec.version!.patch;
    var versionStr = getVersionName();
    var buildNumber = getVersionCode();
    print(Colorize("Update version:$versionStr+$buildNumber ").blue());
    var runnerFile = File("windows/runner/Runner.rc");
    if (runnerFile.existsSync()) {
      var versionNumberReg = RegExp(r'VERSION_AS_NUMBER \d+,\d+,\d+');
      var versionStringReg = RegExp(r'VERSION_AS_STRING "\d+.\d+.\d+"');
      var runnerStr = runnerFile.readAsStringSync();
      runnerStr = runnerStr.replaceFirst(
          versionNumberReg, "VERSION_AS_NUMBER $major,$minor,$patch");
      runnerStr = runnerStr.replaceFirst(
          versionStringReg, 'VERSION_AS_STRING "$major.$minor.$patch"');

      runnerFile.writeAsStringSync(runnerStr);
    }

    //替换安卓版本
    var buildGradleFile = File("android/app/build.gradle");
    if (buildGradleFile.existsSync()) {
      buildGradleFile.readAsStringSync();
      var versionNumberReg = RegExp(r"flutterVersionCode = '\d+'");
      var versionStringReg = RegExp(r"flutterVersionName = '\d.\d(.\d)?'");
      var buildGradleStr = buildGradleFile.readAsStringSync();
      buildGradleStr = buildGradleStr.replaceFirst(
          versionNumberReg, "flutterVersionCode = '${getVersionCode()}'");
      buildGradleStr = buildGradleStr.replaceFirst(
          versionStringReg, "flutterVersionName = '$major.$minor.$patch'");

      buildGradleFile.writeAsStringSync(buildGradleStr);
    }
  }

  String getArtifactFileName() {
    return "${pubspec.name.pascalCase}-${getVersionName()}";
  }

  String getVersionName() {
    return "${pubspec.version!.major}.${pubspec.version!.minor}.${pubspec.version!.patch}";
  }

  String? getVersionCode() {
    return pubspec.version!.build.isEmpty
        ? null
        : pubspec.version!.build.first.toString();
  }
}
