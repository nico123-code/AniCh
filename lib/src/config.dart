import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

late PackageInfo packageInfo;

class AppConfig {
  static RxString version = ''.obs;
  static RxString ua = ''.obs;
  static const baseUrl = 'https://api.emmmm.eu.org';
  static const bilibiliApiProxyUrl = 'https://bili-dm.emmmm.eu.org';
  static const qqVideoApiUrl = 'https://dm.video.qq.com';

  static init() async {
    packageInfo = await PackageInfo.fromPlatform();
    version(packageInfo.version);
    String platform = '';
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'IOS';
    } else if (Platform.isFuchsia) {
      platform = 'Fuchsia';
    } else if (Platform.isLinux) {
      platform = 'Linux';
    } else if (Platform.isMacOS) {
      platform = 'MacOS';
    } else if (Platform.isWindows) {
      platform = 'Windows';
    }

    ua('${packageInfo.packageName} $platform ${packageInfo.version}');
  }
}

/// 带备用地址的 API 客户端：主站 api.emmmm.eu.org 目前不稳定（SSL 报错 / 403），
/// 按官方 1.5.27 的新地址 + api.json 的地址列表顺序重试，某个地址请求失败
/// 就换下一个。只重试 GET 请求，避免重复提交点赞、评论这类写操作。
class ApiClient {
  // 实测（2026-11-21）：anich.sends.eu.org 的 /bangumi/list、/bangumi/latest
  // 都返回 200 真数据；ani.emmmm.eu.org 的 /latest 正常但 /bangumi/list 报 500；
  // api.500403.xyz 的 /bangumi/list 是 404；api.emmmm.eu.org 直接 SSL 报错。
  static const List<String> hosts = [
    'https://anich.sends.eu.org',
    'https://ani.emmmm.eu.org',
    'https://anich.emmmm.eu.org',
    'https://api.emmmm.eu.org',
    'https://api.500403.xyz',
    'https://api.emmmm.eu.org.cdn.cloudflare.net',
  ];

  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: hosts.first,
      headers: {HttpHeaders.userAgentHeader: AppConfig.ua},
    ));
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.requestOptions.method != 'GET') {
            handler.next(e);
            return;
          }
          final tried = List<String>.from(
            e.requestOptions.extra['__triedHosts'] as List? ?? <String>[],
          );
          final current = e.requestOptions.baseUrl;
          if (!tried.contains(current)) tried.add(current);
          final next = hosts.firstWhere(
            (h) => !tried.contains(h),
            orElse: () => '',
          );
          if (next.isEmpty) {
            handler.next(e);
            return;
          }
          final options = e.requestOptions;
          options.baseUrl = next;
          options.extra['__triedHosts'] = tried;
          try {
            final response = await dio.fetch(options);
            handler.resolve(response);
          } on DioException catch (e2) {
            handler.next(e2);
          }
        },
      ),
    );
    return dio;
  }
}
