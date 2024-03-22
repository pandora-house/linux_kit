import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// https://github.com/stsaz/fmedia/blob/master/doc/recording/rec.md
class FMediaLinux {
  var _path = '';

  Future<String> _getPath(String fileName) async {
    final dir = await getApplicationCacheDirectory();
    return p.join(dir.path, fileName);
  }

  Future<bool> _runProcess({
    required String executable,
    required List<String> args,
  }) async {
    final process = await Process.start(
      executable,
      args,
      mode: ProcessStartMode.inheritStdio,
    );

    const success = 0;
    return await process.exitCode == success;
  }

  // TODO handle error process.exitCode != 0
  Future<bool> started() async {
    _path = await _getPath('audio_message.m4a');
    return _runProcess(
      executable: 'fmedia',
      args: [
        '--record',
        '-o',
        _path,
        '-y',
        '--globcmd=listen',
      ],
    );
  }

  Future<String?> stop() async {
    final succeeded = await _runProcess(
      executable: 'fmedia',
      args: [
        '--globcmd=stop',
      ],
    );

    if (succeeded && _path.isNotEmpty) {
      return _path;
    }
    return null;
  }
}
