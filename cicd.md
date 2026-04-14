# Flutter CI/CD 方案草案

## 目标

- `Web`：代码合并到 `main` 后自动校验；打正式版本 `tag` 后自动构建并发布到 `GitHub Pages`
- `Android`：代码合并到 `main` 后自动校验；打正式版本 `tag` 后自动构建 `release APK`，上传到 `GitHub Releases`
- `Android App`：启动时请求更新清单，发现新版本后弹窗提示用户下载并安装覆盖升级
- 当前阶段不纳入 `iOS`
- 当前阶段不使用 `ECS` 作为主链路

## 最终采用的发布策略

- 日常开发：`push` 到 `main` 只做检查，不对用户发布
- 正式发布：创建形如 `v1.0.0` 的 `git tag` 后触发正式构建与发布
- 分发载体：
  - `Web` 使用 `GitHub Pages`
  - `Android APK` 使用 `GitHub Releases`
  - `Android` 更新清单也由 `GitHub` 托管

这样可以避免每次提交都触发真实用户更新。

## 整体工作流

### 1. 代码提交阶段

开发者将代码推送到 `main` 分支后，`GitHub Actions` 执行：

- 安装 Flutter
- 拉取依赖
- 运行静态检查
- 运行测试
- 验证 Web 和 Android 可正常构建

这一阶段只做质量校验，不发布产物给用户。

### 2. 正式发布阶段

开发者创建并推送 `tag`，例如：

```bash
git tag v1.0.0
git push origin v1.0.0
```

`GitHub Actions` 在检测到版本 `tag` 后执行：

- 读取版本号
- 构建 `Web`
- 构建 `Android release APK`
- 生成 `version.json`
- 发布 `Web` 到 `GitHub Pages`
- 上传 `APK` 和 `version.json` 到 `GitHub Releases`

## Web 发布方案

### 托管方式

- 使用 `GitHub Pages`
- 访问地址类似：

```text
https://<github-username>.github.io/<repo-name>/
```

### 用户更新方式

- 用户访问页面时获取最新静态资源
- 用户刷新页面后即可拿到新版本
- 如果后续引入 `service worker` 缓存策略，需要额外设计缓存失效规则

### 发布内容

- `flutter build web` 产物
- 页面入口 `index.html`
- 静态资源目录

## Android 发布方案

### 托管方式

- 使用 `GitHub Releases` 托管 `APK`
- 每个正式版本对应一个 release

### 用户更新方式

- App 启动时或进入设置页时请求远端 `version.json`
- 若远端版本高于本地版本，则显示更新弹窗
- 用户确认后下载 `APK`
- 下载完成后调用系统安装流程
- 安装时覆盖旧版本

### 用户侧实际体验

可以做到：

- App 内检测新版本
- App 内弹窗提示
- 一键开始下载更新包
- 下载后引导用户安装

暂时不考虑：

- 静默安装
- 渠道包管理
- 应用商店并行分发
- 国内下载稳定性增强

## 更新清单设计

更新清单建议使用 `JSON`，例如 `version.json`：

```json
{
  "version": "1.0.0",
  "build_number": 1,
  "release_date": "2026-04-14T12:00:00Z",
  "platform": "android",
  "mandatory": false,
  "title": "发现新版本",
  "description": "修复已知问题并优化体验",
  "apk_url": "https://github.com/<owner>/<repo>/releases/download/v1.0.0/app-release.apk",
  "apk_size": 12345678,
  "apk_sha256": "<sha256>"
}
```

### 字段说明

- `version`：用户可见版本号，对应 `pubspec.yaml` 中的 `version name`
- `build_number`：内部构建号，用于精确比较版本
- `release_date`：发布时间
- `platform`：当前清单所属平台
- `mandatory`：是否强制更新
- `title`：更新弹窗标题
- `description`：更新说明
- `apk_url`：下载地址
- `apk_size`：文件大小，可用于显示下载信息
- `apk_sha256`：下载后校验文件完整性

### 版本比较规则

建议优先比较：

1. `build_number`
2. 若缺失，再比较 `version`

这样可以避免字符串比较带来的歧义。

## 建议拆分的 GitHub Actions

### 工作流一：持续校验

触发条件：

- `push` 到 `main`
- `pull_request` 到 `main`

职责：

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- `flutter build apk --debug` 或 `--release`

目标：

- 保证主分支始终可构建

### 工作流二：正式发布

触发条件：

- 推送 `v*` 格式的 `tag`

职责：

- 构建 `web`
- 构建 `android release apk`
- 生成更新清单
- 上传 `APK` 到 `GitHub Releases`
- 发布 `web` 到 `GitHub Pages`

## 仓库内建议新增的内容

- `.github/workflows/ci.yml`
  - 日常校验流程
- `.github/workflows/release.yml`
  - 正式发布流程
- `scripts/generate_version_json.sh` 或 Dart 脚本
  - 生成 `version.json`
- `lib/` 中的 Android 更新模块
  - 请求清单
  - 比较版本
  - 下载 APK
  - 触发安装

## Android 端应用能力设计

Android App 需要补齐以下能力：

- 获取当前应用版本号
- 请求远端更新清单
- 判断是否需要更新
- 展示更新弹窗
- 下载 APK 到本地
- 调用系统安装器安装 APK

建议把这部分独立成一个更新模块，避免和页面逻辑耦合。

## 版本发布约定

建议采用以下约定：

- `main`：可随时集成，但不直接面向用户发布
- `tag`：只有打 `vX.Y.Z` 才算正式发布
- `pubspec.yaml` 中的版本号在发布前手动维护

示例：

- `version: 1.0.0+1`
- Git tag：`v1.0.0`

建议保持：

- `tag` 的版本号与 `pubspec.yaml` 主版本一致
- `build_number` 单调递增

## 当前阶段明确不做的事情

- `iOS` 自动分发
- `ECS` 托管 APK 或 Web
- 域名与 HTTPS
- OSS/CDN
- Android 国内下载加速
- 多环境发布（dev/staging/prod）
- 灰度发布

## 推荐实施顺序

1. 先建立 `GitHub Actions` 的校验工作流
2. 再建立 `tag` 触发的正式发布工作流
3. 接入 `GitHub Pages`
4. 接入 `GitHub Releases`
5. 生成并发布 `version.json`
6. 在 Android App 内实现更新检测、下载和安装

## 现阶段结论

这套方案的核心特点是：

- 架构简单
- 不依赖自建服务端
- 成本低
- 适合当前新项目快速落地

后续如果用户规模上来，或者 `GitHub` 下载体验不稳定，再把 `APK` 和更新清单迁移到 `ECS` 或 `OSS/CDN` 即可，客户端协议基本可以保持不变。
