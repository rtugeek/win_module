import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:flutter_app_builder/flutter_app_builder.dart';
import 'package:recase/recase.dart';
import 'package:win_module/src/build_mode.dart';
import 'package:win_module/win_module.dart';

import 'app_version.dart';
import 'ext.dart';
import 'git.dart';
import 'main.dart';

class CommandBuild extends Command {
  final WinModule winModule;

  CommandBuild(this.winModule) {
    argParser.addOption('version', valueHelp: '');
    argParser.addOption('job', valueHelp: '');
    argParser.addFlag('force', help: 'If set will force override version');
    argParser.addFlag('publish', help: 'if set will publish to haihaihai.vip');
  }

  @override
  String get name => 'build';

  @override
  String get description => 'build modules';
  var winRootBuildDir = Directory("build/windows/runner/Debug/");
  var androidApkFile = File("build/app/outputs/flutter-apk/app-release.apk");

  @override
  Future run() async {
    String jobArg = argResults?['job'];
    var job = winModule.jobs[jobArg]!;
    var buildMode = job.mode;
    "Build job: ${job.mode} mode, target:${job.target}".logBlue();
    winRootBuildDir = Directory("build/windows/runner/${buildMode.name}/");
    androidApkFile = File(
        "build/app/outputs/flutter-apk/app-${buildMode.name.toLowerCase()}.apk");
    winModule.updateVersion();
    if (job.platform == "windows") {
      //编译子模块
      for (var module in winModule.modules) {
        if (!module.build) {
          _copyFiles(Directory(module.path), winRootBuildDir);
          continue;
        }
        var dir = Directory(module.path);
        logger
            .info(Colorize("=========================================").blue());
        logger.info(Colorize("build module:${module.name}, dir:${dir.absolute}")
            .blue());

        await _tempReplaceDartProjectName(module);
        Process process = await Process.start('flutter',
            ['build', 'windows', '--${buildMode.name.toLowerCase()}'],
            runInShell: true, workingDirectory: dir.path);
        process.stdout.listen((List<int> data) {
          String message = utf8.decoder.convert(data).trim();
          logger.info(Colorize(message).darkGray());
        });
        process.stderr.listen((List<int> data) {
          String message = utf8.decoder.convert(data).trim();
          logger.info(Colorize(message).red());
        });

        int exitCode = await process.exitCode;
        if (exitCode != 0) {
          throw BuildError();
        }
        await _restoreDartProjectName(module);
        //复制文件到父模块
        _copyModuleBuild(module, buildMode);
      }
    }

    //编译父模块
    if (buildMode == BuildMode.Release) {
      "Build root: ${winModule.getArtifactFileName()}";
      var buildDir = await job.build();
      var artifactFile = await job.package(
          buildDir, Directory(winModule.output), job.getArtifactFileName());
      if (argResults!.wasParsed("publish")) {
        //复制文件
        var targetFile = File("../haihaihai/public/${winModule.pubspec.name}/${winModule.pubspec.name.pascalCase}.${job.target}");
        if(!targetFile.existsSync()){
          targetFile.createSync(recursive: true);
        }
        artifactFile.copySync(targetFile.path);
        var versionFile =
            File("../haihaihai/public/${winModule.pubspec.name}/versions.json");
        var versionJson = versionFile.readAsStringSync();
        var appVersions = AppVersions.fromJson(jsonDecode(versionJson));
        if (job.target == "exe") {
          if (appVersions.win == null) appVersions.win = [];
          _newPlatformVersion("win", job.changelog, appVersions.win!);
        } else if (job.target == "apk") {
          if (appVersions.android == null) appVersions.android = [];
          _newPlatformVersion("android", job.changelog, appVersions.android!);
        }
        versionFile.writeAsStringSync(prettyJson(appVersions));
        await Git.addAll();
      }
      "Done".logGreen();
    }
  }

  String prettyJson(dynamic json) {
    var spaces = ' ' * 4;
    var encoder = JsonEncoder.withIndent(spaces);
    return encoder.convert(json);
  }

  _newPlatformVersion(String platform, String changelog,
      List<AppVersion> targetPlatformVersions) {
    //生成版本信息
    for (var element in targetPlatformVersions) {
      if (element.versionName == winModule.getVersionName()) {
        if (argResults!.wasParsed("force")) {
          targetPlatformVersions.remove(element);
        } else {
          "Publish error,version exists".logRed();
          throw BuildError();
        }
        break;
      }
    }

    var newVersion = AppVersion(
        platform: platform,
        appName: winModule.pubspec.name,
        versionName: winModule.getVersionName(),
        releaseAt: DateTime.now().toString(),
        desc: changelog,
        versionCode: winModule.getVersionCode(),
        downloadLink: "https://haihaihai.vip");
    targetPlatformVersions.add(newVersion);
  }

  /// 临时更换DartProject名称
  _tempReplaceDartProjectName(Module module) async {
    var mainCpp = File("${module.path}/windows/runner/main.cpp");
    var old = 'flutter::DartProject project(L"data");';
    var newName = 'flutter::DartProject project(L"${module.name}");';
    var str = mainCpp.readAsStringSync().replaceFirst(old, newName);
    mainCpp.writeAsStringSync(str);
  }

  _copyModuleBuild(Module module, BuildMode mode) async {
    var folderName = mode.name;
    var moduleBuildDir =
        Directory("${module.path}/build/windows/runner/$folderName/");
    //将data目录重命名为子模块名
    var moduleDataDir =
        Directory("${module.path}/build/windows/runner/$folderName/data");
    var newModuleDataDir = Directory(
        "${module.path}/build/windows/runner/$folderName/${module.name}");
    if (newModuleDataDir.existsSync()) {
      newModuleDataDir.deleteSync(recursive: true);
    }
    moduleDataDir.renameSync(newModuleDataDir.path);
    var parentBuildDir = Directory("build/windows/runner/$folderName/");
    _copyFiles(moduleBuildDir, parentBuildDir);
  }

  _copyFiles(Directory source, Directory target) {
    "Copy file from:${source.path} to ${target.path}".logBlue();
    source.listSync(recursive: true).forEach((element) {
      if (element is File) {
        var targetFile =
            File(element.path.replaceAll("${source.path}", target.path));
        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }
        if (targetFile.existsSync()) {
          if (targetFile.path.endsWith(".dll")) {
            "Skip exists DLL file:${targetFile.path}".logBlue();
          } else {
            "Delete exists file:${targetFile.path}".logYellow();
            targetFile.deleteSync(recursive: true);
            element.copySync(targetFile.path);
          }
        } else {
          element.copySync(targetFile.path);
        }
      }
    });
  }

  _restoreDartProjectName(Module module) async {
    var mainCpp = File("${module.path}/windows/runner/main.cpp");
    var old = 'flutter::DartProject project(L"data");';
    var newName = 'flutter::DartProject project(L"${module.name}");';
    var str = mainCpp.readAsStringSync().replaceFirst(newName, old);
    mainCpp.writeAsStringSync(str);
  }
}
