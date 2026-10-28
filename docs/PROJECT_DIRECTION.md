# 当前维护方向

2026-10-21 决定终止 Compose／Kotlin Multiplatform 迁移，继续维护 Flutter。

维护起点为提交 `875c542209162b548ad8283b3a550abbeaeb9945`，对应 2026-10-18 的 `1.2.8+20261018`。保留此后独立确定的 Android 项目签名要求；迁移实验的源码、产物及记录仅作本地封存，不再作为产品开发路线。

优先处理 Android 与 Windows 的实际使用问题，保持轻量、简体中文、既有功能与用户数据。后续改进继续在 `apps/flutter/` 中实施，按变更影响进行验证。

2026-10-27 在 `403bug/c001apk` 增加 macOS 桌面端适配：沿用现有 Flutter 工程，发布 ad-hoc 签名的通用包（Apple Silicon + Intel），首次打开需手动放行；Android 与 Windows 仍是主要维护平台。
