import 'dart:io';

import 'package:haihaihai/src/build_mode.dart';

import '../haihaihai.dart';

class WinModule {
  String name = "";
  String path = "";
  BuildMode? mode;
  bool build = true;
  // 如果为空代表和父项目同级目录
  String? output;

  WinModule(this.name, this.path, this.build, {this.output, this.mode});

  getBuildDirectory(BuildMode parentBuildMode) {
    var buildMode = this.mode ?? parentBuildMode;
    return Directory("$path/build/windows/runner/${buildMode.name}");
  }

  getDataDirectory(BuildMode parentBuildMode) {
    var buildMode = this.mode ?? parentBuildMode;
    return Directory("$path/build/windows/runner/${buildMode.name}/data");
  }

  getModuleDataDirectory(BuildMode parentBuildMode) {
    var buildMode = this.mode ?? parentBuildMode;
    return Directory("$path/build/windows/runner/${buildMode.name}/$name");
  }
}
