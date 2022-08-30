import 'dart:convert';
import 'dart:io';

import 'package:app_package_maker/app_package_maker.dart';
import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:flutter_app_builder/flutter_app_builder.dart';
import 'package:flutter_app_packager/flutter_app_packager.dart';
import 'package:recase/recase.dart';
import 'package:win_module/win_module.dart';

import 'app_version.dart';
import 'ext.dart';
import 'git.dart';
import 'main.dart';
import 'build_mode.dart';

class CommandBuild extends Command {
  final WinModule winModule;

  CommandBuild(this.winModule) {
    argParser.addOption('mode', valueHelp: 'release or debug');
    argParser.addOption('version', valueHelp: '');
    argParser.addFlag('force', help: 'If set will force override version');
    argParser.addFlag('publish', help: 'if set will publish to haihaihai.vip');
  }

  @override
  String get name => 'build';

  @override
  String get description => 'build modules';
  var parentBuildDir = Directory("build/windows/runner/Debug/");

  @override
  Future run() async {
    String mode = argResults?['mode'] ?? 'debug';
    var buildMode = BuildMode.Debug;
    if (BuildMode.Release.name.toLowerCase() == mode.toLowerCase()) {
      buildMode = BuildMode.Release;
    } else if (BuildMode.Profile.name.toLowerCase() == mode.toLowerCase()) {
      buildMode = BuildMode.Profile;
    }
    "Build in: ${buildMode.name} mode, target:${winModule.target}".logBlue();
    parentBuildDir = Directory("build/windows/runner/${buildMode.name}/");
    winModule.updateVersion();

    //编译子模块
    for (var module in winModule.modules) {
      var dir = Directory(module.path);
      logger.info(Colorize("=========================================").blue());
      logger.info(
          Colorize("build module:${module.name}, dir:${dir.absolute}").blue());

      await _tempReplaceDartProjectName(module);
      Process process = await Process.start(
          'flutter', ['build', 'windows', '--${buildMode.name.toLowerCase()}'],
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
    //编译父模块
    if (buildMode == BuildMode.Release) {
      "Build root: ${winModule.getArtifactName()}";
      Process process = await Process.start(
          'flutter', ['build', 'windows', '--${buildMode.name.toLowerCase()}'],
          runInShell: true);
      process.stdout.listen((List<int> data) {
        String message = utf8.decoder.convert(data).trim();
        message.logDarkGray();
      });
      process.stderr.listen((List<int> data) {
        String message = utf8.decoder.convert(data).trim();
        message.logRed();
      });

      int exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw BuildError();
      }
      var packager = FlutterAppPackager();
      parentBuildDir.absolute.path.logBlue();
      MakeResult result = await packager.package(parentBuildDir,
          outputDirectory: Directory(winModule.output),
          platform: "windows",
          target: winModule.target,
          makeArguments: {"artifact_name": winModule.getArtifactName()});
      var outputFile = result.outputFile;
      if (argResults!.wasParsed("publish")) {
        //复制文件
        outputFile.copySync(
            "../haihaihai/public/${winModule.pubspec.name}/${winModule.pubspec.name.pascalCase}.${winModule.target}");
        var versionFile =
            File("../haihaihai/public/${winModule.pubspec.name}/versions.json");
        var versionJson = versionFile.readAsStringSync();
        var appVersions = AppVersions.fromJson(jsonDecode(versionJson));
        if (winModule.target == "exe") {
          if (appVersions.win == null) appVersions.win = [];
          _newPlatformVersion("win", appVersions.win!);
        } else if (winModule.target == "apk") {
          if (appVersions.win == null) appVersions.android = [];
          _newPlatformVersion("android", appVersions.android!);
        }
        versionFile.writeAsStringSync(jsonEncode(appVersions));
        //提交代码
        // Process.start("git", ["commit","-m",""],workingDirectory: "../haihaihai/");
        // await Git.addAll();
        // await Git.commit(winModule.changelog);
        // await Git.tag("V${winModule.getVersionString()}");
        // "Git commit done!,Please run git push in haihaihai.vip manually"
        //     .logYellow();
      }
      "Done".logGreen();
    }
  }

  _newPlatformVersion(
      String platform, List<AppVersion> targetPlatformVersions) {
    //生成版本信息
    if (targetPlatformVersions == null) {
      targetPlatformVersions = [];
    } else {
      for (var element in targetPlatformVersions) {
        if (element.versionName == winModule.getVersionString()) {
          if (argResults!.wasParsed("force")) {
            targetPlatformVersions.remove(element);
          } else {
            "Publish error,version exists".logRed();
            throw BuildError();
          }
          break;
        }
      }
    }
    var newVersion = AppVersion(
        platform: "win",
        appName: winModule.pubspec.name,
        versionName: winModule.getVersionString(),
        releaseAt: DateTime.now().toString(),
        desc: winModule.changelog,
        versionCode: winModule.getBuildCode(),
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
    moduleBuildDir.listSync(recursive: true).forEach((element) {
      if (element is File) {
        var targetFile = File(element.path
            .replaceAll("${moduleBuildDir.path}", parentBuildDir.path));
        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }
        if (targetFile.existsSync()) {
          if (targetFile.path.endsWith(".dll")) {
            "Skip exists DLL file:${targetFile.path}".logBlue();
          } else {
            "Delete exists file:${targetFile.path}".logYellow();
            targetFile.deleteSync(recursive: true);
            element.renameSync(targetFile.path);
          }
        } else {
          element.renameSync(targetFile.path);
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
