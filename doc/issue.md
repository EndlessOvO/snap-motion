# Snap Motion 待解决项

最后更新：2026-06-10

## 当前仓库内进展

- [x] 已创建 `apps/ios/SnapMotion.xcodeproj`，包含 iPhone / iOS 17 SwiftUI App target 和 `SnapMotionTests` 单元测试 target。
- [x] 已配置 `apps/ios/SnapMotion/Supporting/Info.plist`，包含 `NSCameraUsageDescription`。
- [x] 已将 `apps/ios/SnapMotion` 下当前所有 Swift 源码和 `Resources/AvatarAssets.scnassets` 加入 app target。
- [x] 已补本地 SceneKit demo rig：`CuteAvatarTemplate.scn` 包含约定 morph targets；仍保留程序化 fallback 作为资源缺失兜底。
- [x] 已在预览页展示加载中、资源缺失提示和重新加载入口，不再吞掉加载状态。
- [x] 已接入摄像头权限、TrueDepth 支持判断、AR 预览、AR 帧 ingestion、清晰度评分、本地 JPEG 帧导出、真实设备信息 manifest。
- [x] 已串联 iOS 端生成流程：创建 job、上传帧、上传完成、轮询、下载 recipe、写入 `AvatarCache`。
- [x] 已添加本地 Node 后端：支持任务创建、短期上传 URL、JPEG 上传、上传完成、状态轮询、recipe 获取、schema 校验、fixture fallback、可选 OpenAI-compatible provider 和终态原始帧删除。
- [x] 已添加单元测试覆盖 `AvatarRecipe` 解码/编码、`AvatarJob.Status` 终态、`AvatarExpressionMapper` clamp、`CaptureFrameSelector` 和 `FaceQualityEvaluator`。
- [x] 已添加 UI 测试 target，覆盖摄像头拒绝、不支持 TrueDepth、fixture 预览和生成失败状态。
- [x] 已添加后端 `node --test` 覆盖 schema 校验、JPEG-only upload、job/upload/complete/avatar 主流程和 expired 终态清理。
- [x] 已记录首版产品/合规决策：JPEG-only 输入、终态立即删除原始媒体、OpenAI-compatible provider 路线、13+ age gate 要求。
- [x] 已实现 13+ age gate，并添加 UI test launch scenario 覆盖确认流程。
- [x] 已补真机验证矩阵文档：`docs/device-validation-matrix.md`。
- [x] 已添加仓库验证脚本：`scripts/verify.sh`，覆盖后端测试、iOS metadata、Xcode source 引用、SceneKit morph target 检查和 Xcode build。
- [x] `xcodebuild` 构建/测试已在本机完成验证。
  - 2026-06-09 使用 iOS 18.6 Simulator / iPhone 16 跑通 `xcodebuild -project apps/ios/SnapMotion.xcodeproj -scheme SnapMotion -destination 'platform=iOS Simulator,name=iPhone 16' test`。
  - 结果：8 个单元测试、5 个 UI 测试全部通过。
  - 2026-06-10 使用 Xcode 26.5 / iOS 26.5 Simulator / iPhone 17 复跑 `xcodebuild -project apps/ios/SnapMotion.xcodeproj -scheme SnapMotion -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test` 通过。
- [x] 真机架构编译已验证。
  - 2026-06-09 连接 iPhone 17 / iOS 26.4.1 后，`xcodebuild -project apps/ios/SnapMotion.xcodeproj -scheme SnapMotion -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` 通过。
- [x] 真机签名、安装和启动已验证。
  - 2026-06-10 使用 Xcode 26.5、iOS 26.5 SDK、Apple Development 证书和 Team `G758ATTU5P` 完成真机构建。
  - iPhone 17 真机 `xcodebuild -project apps/ios/SnapMotion.xcodeproj -scheme SnapMotion -destination 'platform=iOS,id=00008150-001C24C23A7A401C' build` 通过。
  - `devicectl device install app` 安装成功，`devicectl device process launch` 启动 `local.snapmotion.SnapMotion` 成功。
- [x] 真机测试 target 签名配置已补齐。
  - 2026-06-10 已将 `SnapMotionTests` 和 `SnapMotionUITests` 的 Debug/Release `DEVELOPMENT_TEAM` 对齐到 `G758ATTU5P`，并启用 automatic provisioning。
  - 真机 `xcodebuild test` 需要加 `-allowProvisioningUpdates`，让 Xcode 自动创建 UI test runner 的 development provisioning profile。
  - 本次尝试已越过 test target team / runner profile 配置错误；后续卡在设备临时变为 `unavailable`，需重新连接真机后继续验证。
  - 2026-06-10 复查：CoreDevice 仍能识别已配对 iPhone 17，但 `ddiServicesAvailable = false`、`tunnelState = unavailable`，`xctrace list devices` 显示 iPhone offline，`xcodebuild -showdestinations` 不再列出该真机，USB 枚举未看到 iPhone/Apple Mobile Device。

## P0：先让 App 能装到真机并跑起来

- [x] 创建 Xcode 工程。
  - 已添加 `apps/ios/SnapMotion.xcodeproj`。
  - 配置：Minimum iOS 17.0、Device Family iPhone。

- [x] 把现有 Swift 源码加入 Xcode target。
  - 当前所有 app Swift 文件均已加入 target。
  - `SnapMotionApp.swift` 是 app entry point。

- [x] 配置摄像头权限。
  - `Info.plist` 已加入 `NSCameraUsageDescription`。

- [x] 配置真机签名。
  - 打开 Xcode target 的 `Signing & Capabilities`。
  - 开启 `Automatically manage signing`。
  - 选择可用于真机调试的 Apple ID / Team。
  - 当前本机已有 `Apple Development: 1210020320@qq.com (M8RW79H8C2)` 签名证书，`DEVELOPMENT_TEAM = G758ATTU5P`。

## P0：补齐头像渲染资源

- [x] 添加 SceneKit 模板 Rig。
  - 当前代码会加载 `AvatarAssets.scnassets/CuteAvatarTemplate.scn`。
  - 已加入首版 demo `.scn` 和 `.dae` source；生产发布前仍建议替换为高质量美术资产。

- [x] 模板 Rig 需要暴露约定 morph target。
  - 至少包含 `blink_L`、`blink_R`、`jaw_open`、`smile_L`、`smile_R`。
  - 当前 demo rig 也包含 `brow_up_L`、`brow_up_R`、`mouth_funnel`、`mouth_pucker`、`cheek_squint_L`、`cheek_squint_R`。

- [x] 处理头像资源加载失败状态。
  - 预览页会显示加载提示、fallback 提示和 Reload 入口。

## P1：跑通本地头像预览 Demo

- [x] 确认 `AvatarRecipe.fixture` 能加载并驱动模板头像。
  - 当前预览页已经有 Blink、Mouth、Smile 三个滑杆。
  - 程序化 demo rig 已暴露核心 morph target；真实 rig 上仍需设备/资产验证。

- [x] 将 `AvatarRecipe` 外观参数应用到 SceneKit 模型。
  - 程序化 rig 使用脸型、肤色、眼睛、眉毛、鼻子、嘴、头发和眼镜参数；真实资产的完整材质 URL 下载/贴图仍在缓存工作项中。

- [x] 调整预览页基础交互和错误状态。
  - 已覆盖加载中、资源缺失/fallback 和重新加载入口。

## P1：接入真实相机和 AR 人脸追踪

- [x] 在录入页展示真实相机 / AR 预览。
  - 已接入 `ARFaceCameraView`，由可视 `ARSCNView` 会话驱动录入帧。

- [x] 在录入流程中处理摄像头权限。
  - UI 已使用 `CameraPermissionService` 并覆盖未授权、拒绝、受限、已授权状态。

- [x] 在不支持 TrueDepth 的设备上优雅失败。
  - UI 已展示明确提示；fixture 预览仍可作为开发演示路径。

- [x] 把 `ARFaceTrackingSession.latestFrame` 接入 `FaceEnrollmentViewModel.ingest()`。
  - 已将可视 AR 会话输出的 AR 帧、清晰度和本地 JPEG URL 接入 `ingest(frame:sharpness:imageURL:)`。

- [x] 实现清晰度 / 模糊度检测。
  - 已添加 `ImageSharpnessEvaluator`。

## P1：跑通录入抓帧

- [x] 为每个 `CaptureSlot` 抓取合格帧。
  - 包括 neutralFront、turnLeft、turnRight、lookUp、lookDown、blink、mouthOpen、smile。

- [x] 将录入页进度与实际 slot 完成状态绑定。
  - 由真实 AR 帧质量评分驱动 `completedSlots` 和 `progress`。

- [x] 保存选中的本地 JPEG 帧。
  - 已实现帧导出、压缩和命名；临时文件生命周期仍可后续优化。

- [x] 使用真实设备信息生成 `CaptureManifest`。
  - 已通过 `DeviceInfoProvider` 从 `UIDevice` 和 `Bundle` 读取。

- [x] 增加录入失败和重试状态。
  - 已加入失败提示和 Retry Capture 入口。

## P2：接入实时头像驱动

- [x] 将 ARKit blend shapes 映射到头像 renderer。
  - `AvatarPreviewView` 的 Live 模式会用 `AvatarExpressionMapper` 将 ARKit blend shapes 和 head pose 应用到 renderer。

- [x] 在 `AvatarPreviewView` 中接入 `ARFaceTrackingSession`。
  - 让 blink、jaw open、smile、head pose 等由用户真实表情驱动。
  - 保留滑杆作为调试模式即可。

- [x] 调整 morph multiplier。
  - iOS / 后端 fixture 已为 11 个约定 morph target 配置默认 `AvatarRecipe.rig.morphCalibration`。
  - 真机表现微调仍需纳入设备验证矩阵。

## P2：实现后端生成链路

- [x] 实现后端服务。
  - `apps/server` 支持任务创建、上传 URL、上传完成、状态轮询、头像 recipe 拉取。

- [x] 实现对象存储上传。
  - 本地后端会创建短期 token upload URL，仅接收 `image/jpeg` PUT 上传；生产对象存储可替换此存储层。

- [x] 在 iOS 中串联完整生成流程。
  - 创建 job。
  - 上传所有选中帧。
  - 调用 uploads complete。
  - 轮询 job。
  - 下载 `AvatarRecipe`。
  - 跳转头像预览。

- [x] 接入 OpenAI-compatible 视觉模型。
  - 使用录入帧生成结构化 `AvatarRecipe`。
  - 提示词参考 `docs/avatar-recipe-generation-prompt.md`。
  - 当前实现支持 `OPENAI_COMPATIBLE_BASE_URL` / `OPENAI_COMPATIBLE_API_KEY` / `OPENAI_COMPATIBLE_MODEL`，未配置时使用本地 fixture fallback。

- [x] 后端校验 `AvatarRecipe` schema。
  - schema 在 `docs/avatar-recipe.schema.json`。
  - 后端会拒绝 provider 返回的不合法 recipe；后续可加自动修复 pass。

- [x] 实现原始媒体删除策略。
  - 任务到达 succeeded、failed、expired 等终态后删除原始帧。
  - 保留必要的任务元数据和生成结果。
  - 已有后端测试覆盖 succeeded 和 expired 清理路径。

## P2：本地缓存和离线能力

- [x] 接入 `AvatarCache`。
  - 生成成功下载 recipe 后会写入 `AvatarCache`。

- [x] 缓存头像贴图和模板资源。
  - `AvatarRecipe.Materials` 中有 texture URL。
  - `AvatarAssetCache` 支持下载、缓存命中、过期和失败跳过；真实模板资源仍需资产管线补齐。

- [x] 加入 fixture / demo 模式。
  - `Preview Fixture` 保留为无后端演示入口，正式流程由录入 manifest 启动。

## P3：测试和设备验证

- [x] 添加 iOS 单元测试 target。
  - 覆盖 `AvatarRecipe` 解码。
  - 覆盖 `AvatarJob.Status` 终态判断。
  - 覆盖 `AvatarExpressionMapper` 权重映射和 clamp。
  - 覆盖 `CaptureFrameSelector` 选择最佳帧。
  - 覆盖 `FaceQualityEvaluator` 光照、模糊、姿态评分。

- [x] 添加 UI 测试。
  - 摄像头权限拒绝。
  - 不支持 TrueDepth。
  - 录入失败和重试。
  - 生成失败。
  - 头像预览加载成功。

- [ ] 做真机矩阵验证。
  - 至少验证 iPhone 12+、iOS 17+。
  - 覆盖室内低光、强背光、眼镜、胡子、长发、不同肤色等情况。
  - 已补执行矩阵文档；当前已完成 iPhone 17 真机安装和启动验证。
  - 已尝试真机 `xcodebuild test`；测试 target 签名配置问题已修复，当前需等设备重新恢复 `connected` / DDI services available 后复跑。
  - 待补录入全流程实测结果：低光、强背光、眼镜、胡子、长发、不同肤色和 morph 表现微调。

## P3：产品和合规问题

- [x] 确定后端首版输入格式。
  - 只接受 JPEG 帧，还是也接受短 HEVC 视频。
  - 已记录在 `docs/product-compliance-decisions.md`：首版只接受 JPEG still frames，不接受 HEVC/长视频；后端会拒绝非 `image/jpeg` 上传。

- [x] 确定原始录入媒体保留窗口。
  - 需要和隐私策略、产品体验、调试需求一起决定。
  - 已记录：任务到达 succeeded、failed、expired 后立即删除原始帧。

- [x] 确定首个真实视觉模型供应商。
  - 需要选择 OpenAI-compatible provider，并记录成本、延迟和失败率。
  - 已记录：首个生产集成目标为 OpenAI-compatible vision endpoint；后端记录 provider 和 generation latency，生产上线前需补真实供应商指标。

- [x] 实现年龄门槛或 COPPA 相关处理。
  - 如果面向儿童或可能吸引儿童使用，需要尽早设计合规流程。
  - 已评估并记录：首版不面向儿童；已加入 13+ age gate。
