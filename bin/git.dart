import 'dart:io';

import 'package:flutter_app_builder/flutter_app_builder.dart';

import 'ext.dart';

class Git {
  static tag(String tag) async {
    await tagDelete(tag);
    "Git add tag:$tag".logBlue();
    Process gitTagProcess = await Process.start("git", ["tag", tag],
        workingDirectory: "../haihaihai/");
    int exitCode = await gitTagProcess.exitCode;
    if (exitCode != 0) {
      throw BuildError();
    }
  }

  static tagDelete(String tag) async {
    "Git delete tag:$tag".logBlue();
    Process gitTagProcess = await Process.start("git", ["tag", "-d", tag],
        workingDirectory: "../haihaihai/");
    await gitTagProcess.exitCode;
  }

  static addAll() async {
    "Git add all".logBlue();
    Process gitTagProcess = await Process.start("git", ["add", "."],
        workingDirectory: "../haihaihai/");
    int exitCode = await gitTagProcess.exitCode;
    if (exitCode != 0) {
      throw BuildError();
    }
  }

  static commit(String message) async {
    Process gitTagProcess = await Process.start(
        "git", ["commit", "-m", message],
        workingDirectory: "../haihaihai/");
    int exitCode = await gitTagProcess.exitCode;
    if (exitCode != 0) {
      throw BuildError();
    }
  }

  static push() async {
    "Git push commit".logBlue();
    Process gitTagProcess = await Process.start(
        "git", ["push", "origin", "master"],
        workingDirectory: "../haihaihai/");
    int exitCode = await gitTagProcess.exitCode;
    if (exitCode != 0) {
      throw BuildError();
    }
  }

  static pushWithTag() async {
    "Git push commit with tag".logBlue();
    Process gitTagProcess = await Process.start(
        "git", ["push", "origin", "--tags"],
        workingDirectory: "../haihaihai/");
    int exitCode = await gitTagProcess.exitCode;
    if (exitCode != 0) {
      throw BuildError();
    }
  }
}
