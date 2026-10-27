const biliWebLoginUrl = 'https://passport.bilibili.com/login';

/// 不带 WebView 标记，避免登录页被当成应用内置浏览器而收起短信和密码。
const biliLoginUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

const biliLoginHosts = [
  'bilibili.com',
  'bilibili.cn',
  'hdslb.com',
  'geetest.com',
  'geevisit.com',
  'biliapi.com',
  'biliapi.net',
];

/// 登录页、验证码和跳转回主站允许打开。其它地址留在系统浏览器之外。
bool biliLoginNavigationAllowed(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  switch (uri.scheme) {
    case 'about':
    case 'data':
    case 'blob':
      return true;
    case 'https':
    case 'http':
      break;
    default:
      return false;
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  for (final suffix in biliLoginHosts) {
    if (host == suffix || host.endsWith('.$suffix')) return true;
  }
  return false;
}
