// Kazumi 式首页：大图 Hero + 横排推荐架。
//
// 对照 Kazumi-Swift 的推荐页（Features/Popular/PopularScreen.swift）：
//   * Hero 封面高 = 屏幕高 × 0.70，全幅铺满，底部渐隐融进页面；
//   * 下面是横排货架，一行标题 + 右侧「更多」+ 横向海报；
//   * 顶部是悬浮的玻璃搜索条，底部是悬浮胶囊导航。
//
// 原来的插画/COS 首页没有删，挪到了 lib/src/pages/home/illustration_view.dart，
// 路由 /illustration，底部导航里点「插画」就能回去。
// 玻璃是 BackdropFilter 模糊近似的，Flutter 没有 iOS 26 的系统 glassEffect。

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xs/src/pages/home/kazumi_controller.dart';
import 'package:xs/src/pages/home/widgets/kazumi_home_widgets.dart';
import 'package:xs/src/pages/search/models/search_type.dart';
import 'package:xs/src/widgets/drag_to_move_bar.dart';
import 'package:xs/src/widgets/navbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KazumiHomeController>(
      init: KazumiHomeController(),
      builder: (controller) {
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              Obx(() {
                if (controller.isLoading.value &&
                    controller.bangumiList.isEmpty &&
                    controller.latestList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('推荐加载失败，请检查网络后重试'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.reload,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }
                final heroHeight = MediaQuery.of(context).size.height * 0.70;
                return RefreshIndicator(
                  onRefresh: controller.reload,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: controller.heroItems.isEmpty
                            ? const SizedBox.shrink()
                            : KazumiHero(
                                items: controller.heroItems,
                                height: heroHeight,
                              ),
                      ),
                      if (controller.trendingItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: KazumiShelf(
                            title: '热门番组',
                            onMore: () => Get.toNamed('/bangumi'),
                            children: controller.trendingItems
                                .map((item) => KazumiPosterTile(
                                      image: item.image,
                                      title: item.title,
                                      subtitle:
                                          KazumiHomeController.episodeLabel(
                                              item),
                                      onTap: () => Get.toNamed(
                                        '/bangumi/${item.id}',
                                        arguments: item,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      if (controller.latestList.isNotEmpty)
                        SliverToBoxAdapter(
                          child: KazumiShelf(
                            title: '最近更新',
                            onMore: () => Get.toNamed('/bangumi'),
                            children: controller.latestList
                                .map((item) => KazumiPosterTile(
                                      image: item.image,
                                      title: item.title,
                                      subtitle: '第${item.ep}集',
                                      onTap: () => Get.toNamed(
                                        '/bangumi/${item.id}',
                                        arguments: item,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      if (controller.restItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: KazumiShelf(
                            title: '全部番剧',
                            onMore: () => Get.toNamed('/bangumi'),
                            children: controller.restItems
                                .map((item) => KazumiPosterTile(
                                      image: item.image,
                                      title: item.title,
                                      subtitle:
                                          KazumiHomeController.episodeLabel(
                                              item),
                                      onTap: () => Get.toNamed(
                                        '/bangumi/${item.id}',
                                        arguments: item,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      // 给底部悬浮导航留空位。
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              }),
              // 顶部悬浮玻璃搜索条。
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(child: _GlassSearchBar()),
                    closeWindowButton(
                      positioned: false,
                      padding: const EdgeInsets.only(left: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              NavBar(
                children: [
                  NavItem(
                    icon: Icons.movie,
                    title: '番剧',
                    onTap: () => Get.toNamed('/bangumi'),
                  ),
                  NavItem(
                    icon: Icons.image,
                    title: '插画',
                    onTap: () => Get.toNamed('/illustration'),
                  ),
                  NavItem(
                    icon: Icons.person,
                    title: '我的',
                    onTap: () => Get.toNamed('/profile'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 顶部玻璃搜索条：点进番剧搜索面板。
class _GlassSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withOpacity(0.35),
          child: InkWell(
            onTap: () => Get.toNamed(
              '/search_panel',
              arguments: {'type': SearchType.bangumi},
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.search_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '搜索番剧',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
