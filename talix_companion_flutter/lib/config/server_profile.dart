/// 服务器环境配置 (不可变 DTO)
///
/// - [id]      全局唯一,用于 SharedPreferences 持久化与定位,不要包含会变化的字段
/// - [name]    显示名 (用户可读),用于 UI 列表与顶部 chip
/// - [description] 副标题 (如 "127.0.0.1:48080"),UI 中可省略
/// - [baseUrl] Dio 实际请求前缀
/// - [tenantId] 多租户场景下注入 `tenant-id` header 的值
/// - [publicKey] / [privateKey] 后端 secp256k1 X.509 公钥 (Base64) 与 HEX 私钥,
///               沿用 DecryptAspect 的 ECDH 协议,前端必须在请求头 `Private-Key` 中回传
/// - [isBuiltIn] 是否为内置预置环境 (Local / Staging / Production),true 时禁止删除/编辑
class ServerProfile {
  final String id;
  final String name;
  final String baseUrl;
  final String tenantId;
  final String publicKey;
  final String privateKey;
  final String? description;
  final bool isBuiltIn;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.tenantId,
    required this.publicKey,
    required this.privateKey,
    this.description,
    this.isBuiltIn = false,
  });

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      tenantId: json['tenantId'] as String? ?? '1',
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
      description: json['description'] as String?,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'tenantId': tenantId,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'description': description,
        'isBuiltIn': isBuiltIn,
      };

  ServerProfile copyWith({
    String? name,
    String? baseUrl,
    String? tenantId,
    String? publicKey,
    String? privateKey,
    String? description,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      tenantId: tenantId ?? this.tenantId,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      description: description ?? this.description,
      isBuiltIn: isBuiltIn,
    );
  }

  @override
  bool operator ==(Object other) => other is ServerProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
