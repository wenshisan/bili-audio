import '../../utils/device_type.dart';
import 'base_api_service.dart';

/// 支付接入 (power接口需求(2).csv 第 12 类)
///
/// CSV 标注: 苹果支付 / 谷歌支付 / 信用卡支付, 待开发接口。
///
/// 现状: App Store / Google Play 内购走原生 SDK (in_app_purchase),信用卡走 Stripe SDK。
/// 客户端不直接调 Talix 后端的"扣款"接口 — 由各平台 webhook 通知后端,后端再
/// 通过 [SubscriptionApi.subscribeServicePlan] 标记用户订阅状态。
///
/// 因此本类只提供两个**预留**方法 (创建订单 + 查询订单状态),实际请求由
/// 原生 SDK 完成,后端只承担订单登记 / 状态同步职责。
///
/// 若后端后续提供单独的"创建订单"接口,只需把 [createOrder] 内的占位
/// 路径改成真实路径即可。
class PaymentApi extends BaseApiService {
  PaymentApi._();
  static final PaymentApi instance = PaymentApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'payment-api';

  /// 创建支付订单(预留给后端提供该接口时使用)
  ///
  /// 当前 CSV 未提供此接口,**先抛 [UnimplementedError]** 防止误用。
  /// 实现思路: 调用原生 SDK (in_app_purchase / Stripe) 完成扣款,
  /// 把 receipt 提交到此接口,后端去第三方核销 + 开通订阅。
  ///
  /// [orderType]: 'apple' | 'google' | 'credit_card'
  /// [planId]:    要购买的套餐 id
  /// [purchasePlan]: 1=月付 / 2=年付
  Future<PaymentOrder> createOrder({
    required String orderType,
    required String planId,
    required int purchasePlan,
  }) async {
    throw UnimplementedError(
      'PaymentApi.createOrder: '
      '后端尚未提供创建订单接口,客户端走原生 SDK (in_app_purchase / Stripe). '
      'orderType=$orderType, planId=$planId, purchasePlan=$purchasePlan, '
      'deviceType=${DeviceType.labelOf(DeviceType.current)}',
    );
  }

  /// 查询订单状态(预留)
  Future<PaymentOrder> getOrderStatus({required String orderId}) async {
    throw UnimplementedError(
      'PaymentApi.getOrderStatus: 后端尚未提供查询订单接口. orderId=$orderId',
    );
  }
}

/// 支付订单占位模型 — 后端真正提供后,字段可能变化
class PaymentOrder {
  final String orderId;
  final String orderType; // 'apple' | 'google' | 'credit_card'
  final String planId;
  final int purchasePlan;
  final String status; // 'pending' | 'paid' | 'failed' | 'refunded'
  final String? receipt;

  const PaymentOrder({
    required this.orderId,
    required this.orderType,
    required this.planId,
    required this.purchasePlan,
    required this.status,
    this.receipt,
  });
}
