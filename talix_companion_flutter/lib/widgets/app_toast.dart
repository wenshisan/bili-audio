import 'dart:async';
import 'package:flutter/material.dart';

/// 应用内统一 Toast 通知组件
///
/// 符合 Figma 设计稿样式:
///   - 深灰色背景 (#262626)
///   - 白色文字，Inter 字体
///   - 胶囊形状（大圆角）
///   - 位置：屏幕顶部居中
///   - 入场动画：200ms 淡入 + 上滑
///   - 自动消失：2秒后
///
/// 用法:
/// ```dart
/// AppToast.show(context, '账号未注册');
/// AppToast.show(context, '操作成功', duration: Duration(seconds: 3));
/// ```
class AppToast {
  AppToast._();

  static Timer? _timer;
  static OverlayEntry? _overlayEntry;

  /// 显示 Toast 通知
  ///
  /// [message] - 显示的消息文本
  /// [duration] - 显示时长，默认 2 秒
  /// [position] - 位置，默认顶部
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.top,
  }) {
    // 清除已有 toast
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        position: position,
        onDismiss: () {
          _timer?.cancel();
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _overlayEntry = entry;

    // 自动消失
    _timer = Timer(duration, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  /// 隐藏当前 Toast
  static void hide() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 将后端错误码翻译为用户友好的中文消息
  ///
  /// [errorCode] - 后端返回的错误码 (i18n key)
  /// 返回对应的中文消息，如果找不到映射则返回原始 errorCode
  static String translateError(String errorCode) {
    switch (errorCode) {
      case 'account.not.register':
        return '账号未注册';
      case 'account.not.exists':
        return '账号不存在';
      case 'password.not.match':
        return '密码错误';
      case 'account.disabled':
        return '账号已被禁用';
      case 'login.failure':
        return '登录失败，请稍后重试';
      case 'email.format.incorrect':
        return '邮箱格式不正确';
      case 'password.format.incorrect':
        return '密码格式错误：需8-20位，包含数字、字母和特殊字符';
      case 'header.not.found':
        return '请求头缺失，请重新登录';
      case 'captcha.code.incorrect':
        return '验证码错误';
      case 'captcha.code.expired':
        return '验证码已过期，请重新获取';
      case 'mail.send.failure':
        return '邮件发送失败，请稍后重试';
      case 'verify.code.incorrect':
        return '验证码不正确';
      case 'verify.code.expired':
        return '验证码已过期';
      case 'user.email.exists':
        return '该邮箱已被注册';
      case 'email.verify.failed':
        return '邮箱验证失败，请重新获取验证码';
      case 'email.verify.expired':
        return '邮箱验证码已过期，请重新获取';
      case 'email.verify.code.incorrect':
        return '邮箱验证码不正确';
      case 'token.expired':
        return '登录已过期，请重新登录';
      case 'token.invalid':
        return '登录状态无效，请重新登录';
      case 'token.invalidated.password.change':
        return '由于密码已修改，登录状态已失效，请重新登录';
      case 'login.expired':
        return '登录已过期，请重新登录';
      case 'account.password.error':
        return '账号或密码错误';
      case 'old.password.not.match':
        return '原密码不正确';
      case 'mobile.format.incorrect':
        return '手机号格式不正确';
      case 'session.expire':
        return '会话已过期，请重新登录';
      case 'invalid.header':
        return '请求头无效，请重新登录';
      case 'invalid.signature':
        return '签名验证失败，请重新登录';
      case 'invalid.public.key.rule':
        return '公钥规则无效';
      case 'captcha.code.error':
        return '验证码错误';
      case 'aj.verify.code.error':
        return '验证码错误';
      case 'verify.code.send.limit':
        return '验证码发送过于频繁，请稍后再试';
      case 'verify.code.send.error':
        return '验证码发送失败，请稍后重试';
      case 'user.register.completed':
        return '该邮箱已注册，请直接登录';
      case 'user.mobile.not.exists':
        return '该手机号未注册';
      case 'user.not.register':
        return '该邮箱未注册';
      case 'lenovo.user.info.error':
        return '用户信息获取失败，请重新登录';
      case 'sex.enum.invalid':
        return '性别参数无效';
      case 'too.many.requests':
        return '请求过于频繁，请稍后再试';
      default:
        return errorCode;
    }
  }
}

/// Toast 位置
enum ToastPosition {
  top,
  center,
  bottom,
}

/// Toast Widget
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastPosition position;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // 根据位置计算 top 值
    double top;
    switch (widget.position) {
      case ToastPosition.top:
        top = mediaQuery.padding.top + 16;
        break;
      case ToastPosition.center:
        top = screenHeight / 2 - 20;
        break;
      case ToastPosition.bottom:
        top = screenHeight - mediaQuery.padding.bottom - 60;
        break;
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    constraints: const BoxConstraints(
                      minWidth: 60,
                      maxWidth: 300,
                      minHeight: 32,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}