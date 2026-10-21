/// 把封面地址收成系统媒体控件能接受的绝对 URI。
///
/// B 站接口经常返回 `//i0.hdslb.com/...`。这种协议相对地址
/// `Uri.tryParse` 能过，但 Windows SMTC 会把它当成非法 URI 并 panic。
String? absoluteCoverUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final withScheme = trimmed.startsWith('//') ? 'https:$trimmed' : trimmed;
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return withScheme;
}
