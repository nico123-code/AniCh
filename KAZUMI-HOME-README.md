# AniCh 首页改成 Kazumi 式（大图 Hero + 横排推荐）

改自上游 Sle2p/AniCh（源码对应版本 1.0.0，`lib/` 为准）。只改了首页和默认配色，
番剧详情、播放、弹幕、追番等逻辑一字未动。

## 改完长什么样

- 首页顶部：一张占屏幕 70% 高的大图 Hero，番剧封面全幅铺满，底部渐隐融进页面，
  上面是标题、年份·集数、简介，按钮「立即观看」+ 集数玻璃按钮，5 秒自动轮播，
  下面有轮播圆点。点封面或按钮进番剧详情（和原来索引页的跳转一样）。
- Hero 下面三行横排货架，每行标题 20 号粗体、右侧绿色「更多」，海报 96×144、圆角 12、
  下面两行 12 号居中标题，横着滑：
  1. 热门番组 —— `/bangumi/list` 前 10 条去掉 Hero 的 5 条；
  2. 最近更新 —— `/bangumi/latest`；
  3. 全部番剧 —— 列表剩下的。
- 顶部悬浮玻璃搜索条（点进番剧搜索），底部悬浮胶囊导航：番剧 / 插画 / 我的。
- 默认主题色从蓝 `#3498db` 改成 Kazumi 绿 `#4CAF50`（Kazumi 默认种子色，
  浅色主色 `#3B6939`、深色主色 `#A1D39A` 同款取色思路）。注意：设置里「动态取色」
  默认是开的，开着时颜色跟系统壁纸走；想固定绿色，去设置-外观关掉动态取色再选绿色。

## 改了哪些文件

| 文件 | 改动 |
|---|---|
| `lib/src/pages/home/view.dart` | 重写：新首页（Hero + 货架 + 玻璃搜索条 + 导航） |
| `lib/src/pages/home/kazumi_controller.dart` | 新增：首页数据（列表 + 最近更新，两个口径各自容错） |
| `lib/src/pages/home/widgets/kazumi_home_widgets.dart` | 新增：Hero / 货架 / 海报卡 / 玻璃按钮 |
| `lib/src/pages/home/illustration_view.dart` | 新增：原来的插画/COS 首页原样挪到这里 |
| `lib/src/router.dart` | 新增路由 `/illustration`（旧首页） |
| `lib/src/utils/app_style.dart`、`lib/src/pages/settings/storage/theme_storage.dart`、`lib/src/pages/settings/storage/account_storage.dart` | 默认种子色改绿 |
| `lib/src/pages/settings/theme.dart` | 颜色选择里加了 Kazumi 绿 |
| `.github/workflows/ios-unsigned.yml` | 新增：云端编未签名 IPA |

## 做不到的部分（先说清楚）

- **液态玻璃不是真的**：Kazumi 用 iOS 26 系统 `glassEffect`，Flutter 没有原生对应，
  这里是 `BackdropFilter` 模糊 + 半透明底近似，质感接近、不是 1:1。
- **Kazumi 的「本季新番 / 综合排名 / 收藏榜」三行没有**：AniCh 服务端
  （`api.emmmm.eu.org`）没有这三个口径，`/bangumi/list` 和 `/bangumi/latest`
  是仅有的两个番剧列表接口，造不出真数据，所以只做了热门 / 最近更新 / 全部三行。
- **Hero 没有评分**：AniCh 列表接口不给评分，只有年份和集数，元信息行是「年份 · 集数」。
- **旧首页还在**：插画/COS 内容没删，底部导航点「插画」就能回去。

## 怎么拿到 IPA（没有 Mac 也行）

1. 把这个文件夹推到你自己的 AniCh fork（或新建仓库），推 `main` 分支。
2. 去仓库页面 Actions → `Build AniCh Kazumi Home (unsigned IPA)` → Run workflow。
3. 跑完在 Artifacts 里下载 `AniCh-KazumiHome-unsigned.ipa`，用 AltStore / Sideloadly
   自签安装，和 Kazumi 的未签名 IPA 一样。
4. 本地有 Mac + Flutter 的话：`flutter pub get && flutter build ios --release --no-codesign`，
   再把 `build/ios/iphoneos/Runner.app` 打包成 `Payload/Runner.app` 的 zip 改后缀 `.ipa`。

## 验证

`flutter pub get` + `flutter analyze`（Flutter 3.24.5）通过：全项目只有 1 条 info 级提示，
是原来就有的 `lib/src/pages/bangumi_vod/view.dart:62` 的 `onPopInvoked` 弃用提示，
新加/改动的文件零报错零警告；`dart format` 也已跑过。iOS 真机编译没法在这台 Linux 机器上做，
以 GitHub Actions 那次构建为准；如果 Actions 报错，把日志发回来修。
