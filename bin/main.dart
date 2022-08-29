import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:win_module/win_module.dart';
import 'package:yaml/yaml.dart';

import 'command_build.dart';

final logger = Logger("win_module")
  ..onRecord.listen((record) {
    print(record.message);
  });

//流程：先编译父模块, 1.更新版本号->2.编译
//     再编译子模块, 1.修改DartProject名为模块名
//                 2.编译
//                 3.恢复DartProject名为data
//                 4.复制文件到父模块
//                 5.如果是release模式，再执行打包命令
Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL;
  var winModule = WinModule();
  final runner = CommandRunner('win_module', '');
  runner.argParser.addFlag(
    'version',
    negatable: false,
    help: 'Reports the version of this tool.',
  );
  runner.argParser.addFlag(
    'update-version',
    negatable: false,
    help: 'Make the version of windows/runner/Runner.rc same as pubspec',
  );

  // runner.addCommand(CommandDoctor());
  runner.addCommand(CommandBuild(winModule));

  ArgResults argResults = runner.parse(args);

  if (argResults.wasParsed('version')) {
    String? currentVersion = await _getCurrentVersion();
    if (currentVersion != null) {
      logger.info(currentVersion);
      return;
    }
  } else if (argResults.wasParsed('update-version')) {
    winModule.updateVersion();
    return;
  }
  return runner.runCommand(argResults);
}

Future<String?> _getCurrentVersion() async {
  try {
    var scriptFile = Platform.script.toFilePath();
    var pathToPubSpecYaml = p.join(p.dirname(scriptFile), '../pubspec.yaml');
    var pathToPubSpecLock = p.join(p.dirname(scriptFile), '../pubspec.lock');

    var pubSpecYamlFile = File(pathToPubSpecYaml);

    var pubSpecLockFile = File(pathToPubSpecLock);

    if (pubSpecLockFile.existsSync()) {
      var yamlDoc = loadYaml(await pubSpecLockFile.readAsString());
      if (yamlDoc['packages']['flutter_distributor'] == null) {
        var yamlDoc = loadYaml(await pubSpecYamlFile.readAsString());
        return yamlDoc['version'];
      }

      return yamlDoc['packages']['flutter_distributor']['version'];
    }
  } catch (_) {}
  return null;
}
