import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/bili/bili_login_api.dart';

/// 登录 API (M7.2); bootstrap 中 override
final loginApiProvider = Provider<BiliLoginApi>(
  (ref) => throw UnimplementedError('loginApiProvider 须 override'),
);

/// 当前用户 (M7.2): 启动时加载, 登录后刷新
class LoginController extends AsyncNotifier<BiliUser?> {
  @override
  Future<BiliUser?> build() async {
    final result = await ref.read(loginApiProvider).currentUser();
    final user = result.valueOrNull;
    // 同步到 PlaybackPrefs (handler quality() 与 settings 读取)
    ref.read(playbackPrefsProvider).loggedIn = user != null;
    return user;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(loginApiProvider).currentUser();
      final user = result.valueOrNull;
      ref.read(playbackPrefsProvider).loggedIn = user != null;
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(loginApiProvider).logout();
    ref.read(playbackPrefsProvider).loggedIn = false;
    state = const AsyncData(null);
  }
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, BiliUser?>(LoginController.new);
