// Kazumi 式首页的 UI 组件：Hero + 横排货架 + 海报卡。
//
// 对照 Kazumi-Swift（Features/Popular/）：
//   * PopularScreen.coverHeight = 屏幕高 × 0.70；
//   * PopularPosterTile = 96×144、圆角 12、下面两行 12pt 居中标题；
//   * PopularShelf = 行标题 20 semibold 左 16、「更多」同行居右、横向一张 96 宽 + 12 间距。
//
// 液态玻璃：Kazumi 用 iOS 26 系统 glassEffect，Flutter 没有原生对应，
// 这里用 BackdropFilter 模糊 + 半透明底近似（KazumiPalette.heroFade 那种
// 底部渐隐也一并做了）。不是真 Liquid Glass，别指望一模一样。

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xs/protobuf/bangumi.pb.dart';
import 'package:xs/src/pages/home/kazumi_controller.dart';

/// 一张海报卡：96×144，圆角 12，下面两行 12pt 居中标题。
class KazumiPosterTile extends StatelessWidget {
  const KazumiPosterTile({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String image;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  static const double width = 96;
  static const double height = 144;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: width,
                height: height,
                color: Colors.grey.withOpacity(0.1),
                child: image.isEmpty
                    ? const Icon(Icons.image_not_supported_outlined)
                    : Image.network(
                        image,
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 一行横排货架：标题 + 右侧「更多」+ 横向海报。
class KazumiShelf extends StatelessWidget {
  const KazumiShelf({
    super.key,
    required this.title,
    this.onMore,
    required this.children,
  });

  final String title;
  final VoidCallback? onMore;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onMore != null)
                GestureDetector(
                  onTap: onMore,
                  child: Text(
                    '更多',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: KazumiPosterTile.height + 6 + 34 + 16,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ],
    );
  }
}

/// 首页大图 Hero：全幅封面 + 底部渐隐 + 标题/简介/按钮，5 秒自动轮播。
class KazumiHero extends StatefulWidget {
  const KazumiHero({
    super.key,
    required this.items,
    required this.height,
  });

  final List<bangumi_list_item_> items;
  final double height;

  @override
  State<KazumiHero> createState() => _KazumiHeroState();
}

class _KazumiHeroState extends State<KazumiHero> {
  late final PageController _pageController;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_index + 1) % widget.items.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openDetail(bangumi_list_item_ item) {
    Get.toNamed('/bangumi/${item.id}', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 底部渐隐收口色跟着页面底走，否则渐变尽头和页面底差一截会留接缝
    //（KazumiPalette.heroFade 同一条思路）。
    final base = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return GestureDetector(
                onTap: () => _openDetail(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.image.isEmpty
                        ? Container(color: Colors.grey.withOpacity(0.2))
                        : Image.network(
                            item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey.withOpacity(0.2)),
                          ),
                    // 底部渐隐：文字区可读，底部融进页面底色。
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.45, 0.78, 1],
                          colors: [
                            base.withOpacity(0),
                            base.withOpacity(0.35),
                            base.withOpacity(0.88),
                            base,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (KazumiHomeController.metaLine(item) != null)
                            Text(
                              KazumiHomeController.metaLine(item)!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.black.withOpacity(0.65),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (item.tagline.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.tagline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.black.withOpacity(0.65),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () => _openDetail(item),
                                icon: const Icon(Icons.play_arrow, size: 20),
                                label: const Text('立即观看'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _GlassButton(
                                label: KazumiHomeController.episodeLabel(item),
                                icon: Icons.info_outline,
                                onTap: () => _openDetail(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 轮播圆点。
          if (widget.items.length > 1)
            Positioned(
              right: 16,
              bottom: 8,
              child: Row(
                children: List.generate(widget.items.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.3)),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// 玻璃拟态按钮：模糊 + 半透明底，近似 iOS 26 Liquid Glass。
/// Flutter 没有系统 glassEffect，这是能做到的最接近的办法。
/// 底固定取深色那一档（Kazumi 的玻璃按钮也是这么定的），浅色深色下都可读。
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withOpacity(0.35),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
