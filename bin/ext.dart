import 'package:colorize/colorize.dart';

import 'main.dart';

extension StringExt on String {
  logBlue() {
    logger.info(Colorize(this).blue());
  }

  logRed() {
    logger.info(Colorize(this).blue());
  }

  logGreen() {
    logger.info(Colorize(this).green());
  }

  logDarkGray() {
    logger.info(Colorize(this).darkGray());
  }
}
