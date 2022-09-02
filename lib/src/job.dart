import 'dart:io';

import 'package:app_package_maker/app_package_maker.dart';
import 'package:flutter_app_builder/flutter_app_builder.dart';
import 'package:flutter_app_packager/flutter_app_packager.dart';
import 'package:recase/recase.dart';
import 'package:win_module/src/build_mode.dart';

class Job {
  String target = "exe";
  String changelog = "1.修复部分设备不会提醒.\n2.添加下班提醒";
  String platform = "windows";
  bool cleanBeforeBuild = false;
  BuildMode mode = BuildMode.Release;

  String versionName = "";
  String versionCode = "";
  String projectName = "";

  Future<Directory> build() async {
    BuildResult result = await FlutterAppBuilder().build(platform, target,
        cleanBeforeBuild: cleanBeforeBuild,
        buildArguments: {},
        onProcessStdOut: (List<int> data) {},
        onProcessStdErr: (List<int> data) {});
    return result.outputDirectory;
  }

  Future<File> package(
      Directory directory, Directory outputDir, String artifactName) async {
    MakeResult result = await FlutterAppPackager().package(directory,
        outputDirectory: outputDir,
        platform: platform,
        target: target,
        makeArguments: {"artifact_name": artifactName});
    return result.outputFile;
  }

  String getArtifactFileName(){
    return "${projectName.pascalCase}_${versionName}.$target";
  }

  Job.fromJson(Map<String, dynamic> json) {
    target = json['target'];
    changelog = json['changelog'];
    cleanBeforeBuild =
        (json['cleanBeforeBuild'] ?? "false") == "true" ? true : false;
    platform = json['platform'];
    if (json['mode'] == null) {
      mode = BuildMode.Release;
    } else if (json['mode'] == "debug") {
      mode = BuildMode.Debug;
    } else if (json['mode'] == "profile") {
      mode = BuildMode.Profile;
    } else {
      mode = BuildMode.Release;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['target'] = this.target;
    data['changelog'] = this.changelog;
    data['cleanBeforeBuild'] = this.cleanBeforeBuild;
    data['platform'] = this.platform;
    data['mode'] = this.mode.name.toLowerCase();
    return data;
  }
}
