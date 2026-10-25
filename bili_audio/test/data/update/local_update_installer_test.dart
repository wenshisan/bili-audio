import 'dart:io';

import 'package:bili_audio/data/update/local_update_installer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS 下载的磁盘映像会去掉隔离标记', () async {
    if (!Platform.isMacOS) return;

    final file = File(
      '${Directory.systemTemp.path}/bili_quarantine_${DateTime.now().microsecondsSinceEpoch}.dmg',
    );
    await file.writeAsString('not a disk image');
    addTearDown(() async {
      if (file.existsSync()) await file.delete();
    });

    final set = await Process.run('/usr/bin/xattr', [
      '-w',
      'com.apple.quarantine',
      '0086;0;bili_audio;',
      file.path,
    ]);
    expect(set.exitCode, 0);

    await clearMacDownloadQuarantine(file.path);

    final left = await Process.run('/usr/bin/xattr', [
      '-p',
      'com.apple.quarantine',
      file.path,
    ]);
    expect(left.exitCode, isNot(0));
  });
}
