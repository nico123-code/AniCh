// Kazumi 式首页的数据层。
//
// 对照 Kazumi-Swift 的 PopularController（Features/Popular/PopularController.swift）：
//   * 焦点区吃第一行的前 5 条，不单独发请求；
//   * 每行 10 条，点「更多」进列表页。
//
// AniCh 自己的服务端只有两个可用的番剧列表口径，所以这里的行是：
//   * 热门番组 —— GET /bangumi/list 的前 10 条（去掉 Hero 的前 5 条后剩 5 条，
//     不足 10 条就如实显示，不凑数）；
//   * 最近更新 —— GET /bangumi/latest；
//   * 全部番剧 —— /bangumi/list 的其余条目。
// Kazumi 的「本季新番 / 综合排名 / 收藏榜」三行 AniCh 服务端没有对应接口，
// 没法凭空造数据，所以不做假行。

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:xs/protobuf/bangumi.pb.dart';
import 'package:xs/src/apis/bangumi.dart';

class KazumiHomeController extends GetxController {
  /// 焦点区最多几张（Kazumi PopularController.heroLimit = 5）。
  static const int heroLimit = 5;

  /// 一行最多几张（Kazumi PopularController.rowSize = 10）。
  static const int rowSize = 10;

  final RxList<bangumi_list_item_> bangumiList = <bangumi_list_item_>[].obs;
  final RxList<bangumi_latest_item_> latestList = <bangumi_latest_item_>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  /// 焦点区：番剧列表的前 5 条。
  List<bangumi_list_item_> get heroItems =>
      bangumiList.take(heroLimit).toList();

  /// 热门番组行：去掉 Hero 的 5 条之后再取 10 条（Kazumi 会把 Hero 的几部
  /// 从第一行剔掉，见 PopularController 的注释）。
  List<bangumi_list_item_> get trendingItems =>
      bangumiList.skip(heroLimit).take(rowSize).toList();

  /// 全部番剧行：Hero + 热门行之后剩下的。
  List<bangumi_list_item_> get restItems =>
      bangumiList.skip(heroLimit + rowSize).toList();

  @override
  void onInit() {
    load();
    super.onInit();
  }

  Future<void> load() async {
    isLoading(true);
    hasError(false);
    // 两个口径各自 try/catch：一个挂了不拖垮另一个。
    await Future.wait([_loadList(), _loadLatest()]);
    isLoading(false);
    hasError(bangumiList.isEmpty && latestList.isEmpty);
  }

  Future<void> reload() => load();

  Future<void> _loadList() async {
    try {
      final response = await BangumiApi.getBangumiList();
      final data = bangumi_list_.fromBuffer(response.data);
      bangumiList.assignAll(data.data);
    } catch (e) {
      debugPrint('KazumiHomeController list failed: $e');
    }
  }

  Future<void> _loadLatest() async {
    try {
      final response = await BangumiApi.getBangumiLatest();
      final data = bangumi_latest_.fromBuffer(response.data);
      latestList.assignAll(data.data);
    } catch (e) {
      debugPrint('KazumiHomeController latest failed: $e');
    }
  }

  /// 集数文案，与番剧索引页（pages/bangumi/views/index.dart）同一口径。
  static String episodeLabel(bangumi_list_item_ item) {
    if (item.status.isEmpty) return '敬请期待';
    if (item.status == 'released') return '全1集';
    if (item.status == 'finale') return '全${item.episodesTotal}集';
    return '更新至第${item.episode}集';
  }

  /// 年份：date 是 double 型时间戳（秒或毫秒都可能，先归一化到毫秒）。
  static String yearOf(bangumi_list_item_ item) {
    if (item.date <= 0) return '';
    final ms = item.date > 1e12 ? item.date : item.date * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms.toInt()).year.toString();
  }

  /// Hero 元信息行，对照 Kazumi PopularPoster.metaLine：
  /// 「2023 · 28 集 · 9.4」—— AniCh 列表接口没有评分，只有年份和集数。
  static String? metaLine(bangumi_list_item_ item) {
    final parts = <String>[];
    final year = yearOf(item);
    if (year.isNotEmpty) parts.add(year);
    if (item.episodesTotal > 0) {
      parts.add('${item.episodesTotal}集');
    } else if (item.episode > 0) {
      parts.add('第${item.episode}集');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
