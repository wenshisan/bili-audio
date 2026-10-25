import 'dart:io';

import 'package:bili_audio/data/update/local_update_installer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

  test('正在运行的应用包就地替换，转存目录改写到应用程序', () {
    final running = p.join(
      'Applications',
      'bili_audio.app',
      'Contents',
      'MacOS',
      'bili_audio',
    );
    expect(
      macUpdateDestination(executable: running),
      p.join('Applications', 'bili_audio.app'),
    );

    final translocated = p.join(
      'private',
      'var',
      'AppTranslocation',
      'ABC',
      'd',
      'bili_audio.app',
      'Contents',
      'MacOS',
      'bili_audio',
    );
    expect(
      macUpdateDestination(executable: translocated, applicationsDir: 'Apps'),
      p.join('Apps', 'bili_audio.app'),
    );
    expect(
      macUpdateDestination(executable: p.join('usr', 'bin', 'bili_audio')),
      p.join('/Applications', 'bili_audio.app'),
    );
  });

  test('替换脚本先确认隔离标记已去掉，再换掉旧应用', () {
    final script = macReplaceAppScript(
      dmgPath: "/tmp/a'b.dmg",
      destination: '/Applications/My Apps/bili_audio.app',
    );
    expect(script, contains(r"'/tmp/a'\''b.dmg'"));
    expect(script, contains("'/Applications/My Apps/bili_audio.app'"));
    expect(script, contains('xattr -dr com.apple.quarantine'));
    expect(
      script.indexOf('隔离标记无法清除'),
      lessThan(script.indexOf('mv "\$dest" "\$backup"')),
    );
  });

  test('替换脚本能通过 bash 语法检查', () async {
    if (!Platform.isMacOS) return;
    final script = macReplaceAppScript(
      dmgPath: '/tmp/bili audio.dmg',
      destination: '/Applications/bili_audio.app',
    );
    final file = File(
      '${Directory.systemTemp.path}/bili_mac_update_${DateTime.now().microsecondsSinceEpoch}.sh',
    );
    await file.writeAsString(script);
    addTearDown(() async {
      if (file.existsSync()) await file.delete();
    });
    final checked = await Process.run('/bin/bash', ['-n', file.path]);
    expect(checked.exitCode, 0, reason: '${checked.stderr}');
  });

  test('沙盒外安装失败时改用管理员权限', () async {
    final calls = <bool>[];
    await installDownloadedMacDisk(
      '/tmp/a.dmg',
      executable: p.join(
        'Applications',
        'bili_audio.app',
        'Contents',
        'MacOS',
        'bili_audio',
      ),
      runShell: (bash, {required bool administrator}) async {
        calls.add(administrator);
        expect(bash, contains("'/tmp/a.dmg'"));
        if (!administrator) {
          return ProcessResult(0, 1, '', 'Operation not permitted');
        }
        return ProcessResult(0, 0, '', '');
      },
    );
    expect(calls, [false, true]);
  });

  test('磁盘映像内容不对时不提权', () async {
    var admins = 0;
    await expectLater(
      installDownloadedMacDisk(
        '/tmp/a.dmg',
        executable: p.join(
          'Applications',
          'bili_audio.app',
          'Contents',
          'MacOS',
          'bili_audio',
        ),
        runShell: (bash, {required bool administrator}) async {
          if (administrator) admins++;
          return ProcessResult(0, 1, '', '磁盘映像里没有 bili_audio.app');
        },
      ),
      throwsA(
        isA<InstallLaunchException>().having(
          (error) => error.message,
          'message',
          contains('磁盘映像里没有'),
        ),
      ),
    );
    expect(admins, 0);
  });

  test('用户取消密码时不再提权', () async {
    var admins = 0;
    await expectLater(
      installDownloadedMacDisk(
        '/tmp/a.dmg',
        executable: p.join(
          'Applications',
          'bili_audio.app',
          'Contents',
          'MacOS',
          'bili_audio',
        ),
        runShell: (bash, {required bool administrator}) async {
          if (administrator) admins++;
          return ProcessResult(0, 1, '', 'User canceled. (-128)');
        },
      ),
      throwsA(
        isA<InstallLaunchException>().having(
          (error) => error.message,
          'message',
          '已取消安装',
        ),
      ),
    );
    expect(admins, 0);
  });

  test('启动时删掉更新留下的旧副本', () async {
    final root = await Directory.systemTemp.createTemp('bili_prev_');
    addTearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });
    final exe = p.join(
      root.path,
      'bili_audio.app',
      'Contents',
      'MacOS',
      'bili_audio',
    );
    await File(exe).create(recursive: true);
    final previous = Directory(
      p.join(root.path, '.bili_audio.app.previous.42'),
    );
    await previous.create();
    await File(p.join(previous.path, 'old')).writeAsString('y');
    final keep = Directory(p.join(root.path, 'Other.app'));
    await keep.create();

    await deletePreviousMacAppBundles(executable: exe);

    expect(previous.existsSync(), isFalse);
    expect(keep.existsSync(), isTrue);
    expect(File(exe).existsSync(), isTrue);
  });
}
