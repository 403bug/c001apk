# GitHub Actions 云端构建

[返回开发指南](DEVELOPMENT.md) · [查看 Actions](https://github.com/TG-Twilight/c001apk/actions/workflows/build.yml)

配置入口为 [Build workflow](../.github/workflows/build.yml)。固定 Flutter 3.24.5 / Dart 3.5.4，
Android 使用 Temurin JDK 17，所有 Flutter 命令从 `apps/flutter/` 执行。
依赖安装使用 `--enforce-lockfile`，不在云端自动升级依赖；Action 引用固定到完整提交 SHA。

## 运行方式

- 推送 `main` 或提交 PR，且改动 Flutter 工程或 workflow 时，自动执行离线检查和构建。
- 在 Actions → Build → Run workflow 手动运行，默认 `android_release=true`，生成正式签名 Android APK。
- 没有正式签名 Secrets 的 fork 可将 `android_release` 取消勾选，执行 debug 构建。
- 勾选 `ios` 可额外执行 iOS 真机 arm64 的无签名编译检查；它不生成可安装 IPA。

静态分析遇 error/warning 时失败；既有 info 级命名等提示继续显示，暂不阻断。
普通测试只使用离线合成夹具，两项在线检查默认跳过。CI 不操作真实账号。

| 任务 | Runner | 产物 |
| --- | --- | --- |
| 离线分析/测试 | `ubuntu-22.04` | 检查日志 |
| Windows release | `windows-2022` | x86_64 ZIP，包含 EXE、DLL 和完整 `data/` |
| Linux release | `ubuntu-22.04` | x86_64 tar.gz，包含完整 bundle |
| Android debug | `ubuntu-22.04` | 三 ABI 开发证书 APK，保留 7 天 |
| Android release | `ubuntu-22.04` | `arm64-v8a` / `armeabi-v7a` / `x86_64` 正式签名 APK，分别上传 |
| iOS（可选） | `macos-14` | arm64 无签名编译日志 |

release 包名包含 `pubspec.yaml` 的版本；桌面运行目录完整打包，Linux 可执行权限通过 tar 保留。
正式 APK 和桌面归档提供 SHA-256 文件校验清单，release artifacts 保留 14 天。
从运行详情的 Artifacts 下载；此 workflow 不创建 GitHub Release。

当前版本文件为 `1.1.0+20261014`。Flutter 3.24.5 分包会在基础 Android `versionCode`
上叠加 ABI 偏移：`armeabi-v7a` 为 +1000、`arm64-v8a` 为 +2000、`x86_64` 为 +4000。
因此这批 APK 的实际编码分别为 `20262014`、`20263014`、`20265014`，
`versionName` 均为 `1.1.0`；文件名仍使用 pubspec 版本。后续版本编码维护应沿用这一分包规则。

桌面 ARM64 不列入当前目标：Flutter 3.24.5 官方 Windows/Linux SDK 发布包只有 x64，
旧工具链的原生插件也未完成 ARM64 验证。移动端 arm64 不受这一决定影响。

## Android 正式签名

维护者在仓库 Settings → Secrets and variables → Actions 配置：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 正式 JKS 的 Base64，单行编码 |
| `REVIA_KS_PASS` | 同时用于 store/key 的密码 |

当前正式身份的 alias 为 `秋风のとおり道`，证书 SHA-256 为
`EA:38:5A:FC:82:E1:98:24:EE:A8:A8:86:8E:D3:65:DF:03:E9:88:6B:BB:A3:3E:47:E1:E0:4B:43:EC:65:CB:67`。
以上是公开证书元数据；其他 fork 如使用自己的密钥，须同时调整 alias 和期望指纹。

手动 release 任务先检查 Secrets，再将 JKS 恢复到 runner 临时目录，并用
`keytool -storepass:env` 核对公开证书。密码仅注入需要它的步骤环境，
不放在命令参数或 `key.properties` 中。构建后逐个 APK 使用 `apksigner verify` 核对指纹，
同时检查每个包仅含指定 ABI 的 AOT 库。校验失败不会上传安装包。

清理步骤使用 `always()`，在成功或失败后移除临时 JKS 和证书。
不缓存项目/Gradle 目录，不上传整个 workspace，仅上传指定的分发文件；
JKS、密码和 Base64 不进入 Git 或 artifacts。公共 PR 和自动 push 不读取正式签名 Secrets。
GitHub Secrets 的二进制存储方式见 [官方文档](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)。

## 排查失败

先检查失败步骤日志，区分 SDK/依赖下载、离线检查、原生编译、签名和产物打包错误。
Android 强制 `flutter config --jdk-dir="$JAVA_HOME"`，避免 runner 自带 Android Studio JBR
覆盖 JDK 17；显式安装 Android command-line tools 16.0（12266719），不依赖 runner 预装
`sdkmanager`。SDK packages 在构建前显式安装，Gradle wrapper 由 Flutter 在干净检出时补齐。
Windows 使用带 VS 2022 的固定 runner，Linux 安装 GTK/CMake/Ninja 等开发依赖。

缺少 Secrets 或证书不匹配时补齐正确材料，不用 debug 密钥替代 release。
iOS 只检查编译，后续正式分发需要独立的 Apple 证书、描述文件与签名配置。
一次云端构建成功只证明该提交的检查和编译，不代表全部线上 API 或真实界面已验收。
