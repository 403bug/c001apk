# macOS 安装与构建

[返回项目首页](../README.md) · [开发指南](DEVELOPMENT.md) · [云端构建](CI.md)

当前 macOS 包为 **ad-hoc 签名、未公证**，用于本分支的桌面端适配。首次打开需要手动放行，之后可正常使用。

## 支持范围

- macOS 12 及以上。
- 通用二进制：Apple Silicon（arm64）与 Intel（x86_64）原生运行，不需要 Rosetta。
- 已知缺口：保存图片不可用；应用内更新会回退到 Release 页面；首次打开需要手动放行。

## 获取安装包

`Build` 工作流会生成 `c001apk-macos-universal-release` artifact，包含：

- `c001apk-<版本>-macos-universal.zip`
- `SHA256SUMS.txt`

维护者也会把同样的 zip 附加到 GitHub Release。解压后把 `c001apk.app` 拖到 `/Applications`。

发布到 Release 时，从 Actions 下载 `c001apk-macos-universal-release`，把 zip 和 `SHA256SUMS.txt` 一起附加，并在 Release 说明中链接本文档的首次打开步骤。workflow 不自动创建 Release。

校验：

```bash
shasum -a 256 c001apk-*-macos-universal.zip
codesign --verify --deep --strict /Applications/c001apk.app
```

## 首次打开

包没有 Apple Developer ID 签名，也没有经过 Apple 公证，Gatekeeper 会拦截。

### macOS 15 及以上

1. 双击 `c001apk.app`，看到“无法验证开发者”的提示。
2. 打开 系统设置 → 隐私与安全性，滚动到底部。
3. 点击“仍要打开”，再确认一次。

### macOS 14 及更早

右键点击 `c001apk.app` → 打开 → 在提示中再次选择“打开”。

### 终端方式

```bash
xattr -cr /Applications/c001apk.app
```

这会移除下载产生的 quarantine 标记。只对你自己信任的来源执行；从本仓库 Actions/Release 下载的包可以这样处理。

> [!NOTE]
> 这不是“安装失败”，也不是包损坏。ad-hoc 签名保证包完整，但无法证明开发者身份；Apple 公证要求付费的 Developer ID。后续如果接入 Developer ID + notarization，这一步就可以省略。

## 从源码构建

前提：

- Flutter 3.47.7 及以上（`pubspec.yaml` 要求 `flutter: '>=3.47.7'`）。
- Xcode 15 及以上；CocoaPods。
- 首次 `pod install` 会从 CocoaPods trunk 拉取 `OrderedSet`，需要网络。
- `macos/Podfile`、`macos/Podfile.lock` 和 Xcode 工程里的 CocoaPods / Swift Package 集成已提交。

```bash
cd apps/flutter
flutter pub get --enforce-lockfile
dart tool/build_release.dart macos --release
open build/macos/Build/Products/Release
```

`tool/build_release.dart` 会从 `git remote get-url origin` 识别当前仓库并注入 `C001APK_REPOSITORY`，因此 fork 构建出来会查询自己的 Release。也可以直接用 `flutter build macos --release --dart-define=C001APK_REPOSITORY=<owner>/<repo>`。

如果 `pub.flutter-io.cn` 镜像不可用，可使用官方源：

```bash
PUB_HOSTED_URL=https://pub.dev flutter pub get --enforce-lockfile
```

产物为 `build/macos/Build/Products/Release/c001apk.app`，release 默认同时包含 arm64 和 x86_64。

## 包内容校验

```bash
app=build/macos/Build/Products/Release/c001apk.app
lipo "$app/Contents/MacOS/c001apk" -verify_arch arm64
lipo "$app/Contents/MacOS/c001apk" -verify_arch x86_64
plutil -extract LSMinimumSystemVersion raw "$app/Contents/Info.plist"   # 12.0
codesign -d --entitlements :- "$app" 2>/dev/null
codesign --verify --deep --strict "$app"
```

沙箱权限应包含：

- `com.apple.security.app-sandbox`
- `com.apple.security.network.client`
- `com.apple.security.files.user-selected.read-write`

## 已知限制

- **保存图片不可用**：`saver_gallery` 和 `permission_handler` 没有 macOS 实现，会提示“图片保存失败”。可在浏览器中打开图片后保存。
- **应用内更新**：更新检测查询构建时注入的仓库（CI 为当前 fork，本地默认 `403bug/c001apk`），并匹配 Release 里的 `macos-universal.zip`；下载后仍需按本文首次打开步骤放行。
- **窗口标题栏**：桌面端使用原生标题栏，交通灯按钮不再覆盖页面内容。
- **Bundle ID**：仍为 `com.example.c001apk.flutter`。正式发布前应改成稳定且唯一的 ID；改 ID 会更换沙箱容器，旧数据不会自动迁移。
- **本地网络**：如果通过局域网代理访问网络，macOS 会询问本地网络权限；正常直连 Internet 时不需要。

## 后续：接入 Developer ID

如果之后有 Apple Developer Program 账号，可以在 `build.yml` 的 `macos` job 里增加：

1. 导入 Developer ID Application 证书到临时 keychain。
2. 开启 Hardened Runtime，使用 Developer ID 签名并加时间戳。
3. `xcrun notarytool submit` 公证，`xcrun stapler staple` 装订票据。
4. 重新用 `ditto` 压缩；验收 `spctl --assess --type execute` 应为 `accepted`。

那时就可以去掉本文档里的手动放行步骤。
