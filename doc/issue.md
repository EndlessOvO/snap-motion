# Snap Motion 待解决项

最后更新：2026-06-09

## P0：先让 App 能装到真机并跑起来

- [ ] 创建 Xcode 工程。
  - 当前仓库只有 iOS 源码骨架，没有 `.xcodeproj` 或 `.xcworkspace`。
  - 需要在 Xcode 中创建 SwiftUI iOS App target。
  - 建议配置：Minimum iOS 17.0、Device Family iPhone。

- [ ] 把现有 Swift 源码加入 Xcode target。
  - 添加 `apps/ios/SnapMotion` 下所有 `.swift` 文件。
  - 确认 `SnapMotionApp.swift` 是 app entry point。

- [ ] 配置摄像头权限。
  - 在 `Info.plist` 中加入 `NSCameraUsageDescription`。
  - 文案可沿用 `apps/ios/SnapMotion/README.md` 中的建议值。

- [ ] 配置真机签名。
  - 打开 Xcode target 的 `Signing & Capabilities`。
  - 开启 `Automatically manage signing`。
  - 选择可用于真机调试的 Apple ID / Team。

## P0：补齐头像渲染资源

- [ ] 添加真实 SceneKit 模板 Rig。
  - 当前代码会加载 `AvatarAssets.scnassets/CuteAvatarTemplate.scn`。
  - 这个文件目前只是规划中的占位资源，需要替换为真实 `.scn` 资产。

- [ ] 模板 Rig 需要暴露约定 morph target。
  - 至少包含 `blink_L`、`blink_R`、`jaw_open`、`smile_L`、`smile_R`。
  - 后续可扩展 `brow_up_L`、`brow_up_R`、`mouth_funnel`、`mouth_pucker`、`cheek_squint_L`、`cheek_squint_R`。

- [ ] 处理头像资源加载失败状态。
  - `AvatarPreviewViewModel.load()` 目前吞掉加载错误。
  - 应显示可理解的错误信息，方便真机调试。

## P1：跑通本地头像预览 Demo

- [ ] 确认 `AvatarRecipe.fixture` 能加载并驱动模板头像。
  - 当前预览页已经有 Blink、Mouth、Smile 三个滑杆。
  - 需要在真实 rig 上验证 morph target 名称和权重效果。

- [ ] 将 `AvatarRecipe` 外观参数应用到 SceneKit 模型。
  - 当前 renderer 只加载 scene 和 morpher。
  - 还没有应用脸型、肤色、眼睛、眉毛、鼻子、嘴、头发、配饰和材质 URL。

- [ ] 调整预览页基础交互和错误状态。
  - 加载中状态。
  - 资源缺失状态。
  - 重新加载 / 返回重试入口。

## P1：接入真实相机和 AR 人脸追踪

- [ ] 在录入页展示真实相机 / AR 预览。
  - `FaceEnrollmentView` 目前只有占位面板和椭圆引导。
  - 需要接入 `ARFaceTrackingSession.session` 到可显示的 AR/相机 view。

- [ ] 在录入流程中处理摄像头权限。
  - 已有 `CameraPermissionService`，但 UI 尚未使用。
  - 需要覆盖未授权、拒绝、受限、已授权状态。

- [ ] 在不支持 TrueDepth 的设备上优雅失败。
  - `ARFaceTrackingSession.isSupported` 已有判断。
  - UI 需要展示明确提示，并提供退出或降级方案。

- [ ] 把 `ARFaceTrackingSession.latestFrame` 接入 `FaceEnrollmentViewModel.ingest()`。
  - 当前 `ingest(frame:sharpness:imageURL:)` 没有被调用。
  - 还需要同步生成或保存对应的本地帧图片 URL。

- [ ] 实现清晰度 / 模糊度检测。
  - `FaceQualityEvaluator` 接收 `sharpness`，但目前没有实际图像 sharpness 计算管道。

## P1：跑通录入抓帧

- [ ] 为每个 `CaptureSlot` 抓取合格帧。
  - 包括 neutralFront、turnLeft、turnRight、lookUp、lookDown、blink、mouthOpen、smile。

- [ ] 将录入页进度与实际 slot 完成状态绑定。
  - 当前 view model 已有 `completedSlots` 和 `progress`。
  - 需要由真实 AR 帧驱动，而不是静态 UI。

- [ ] 保存选中的本地 JPEG 帧。
  - `CaptureManifest.CapturedFrame.localURL` 已定义。
  - 需要实现帧导出、压缩、命名和临时文件清理。

- [ ] 使用真实设备信息生成 `CaptureManifest`。
  - 当前 `FaceEnrollmentView` 中写死了 model、osVersion、appVersion。
  - 需要从设备和 bundle 中读取。

- [ ] 增加录入失败和重试状态。
  - 技术规划中要求覆盖 failure 和 retry。
  - 当前 UI 只有继续按钮。

## P2：接入实时头像驱动

- [ ] 将 ARKit blend shapes 映射到头像 renderer。
  - 已有 `AvatarExpressionMapper`，但预览页还没有使用它。

- [ ] 在 `AvatarPreviewView` 中接入 `ARFaceTrackingSession`。
  - 让 blink、jaw open、smile、head pose 等由用户真实表情驱动。
  - 保留滑杆作为调试模式即可。

- [ ] 调整 morph multiplier。
  - 需要基于真机表现调 `AvatarRecipe.rig.morphCalibration`。

## P2：实现后端生成链路

- [ ] 实现后端服务。
  - 当前仓库没有后端代码。
  - 需要支持任务创建、上传 URL、上传完成、状态轮询、头像 recipe 拉取。

- [ ] 实现对象存储上传。
  - `UploadClient` 已能 PUT 文件到预签名 URL。
  - 需要后端创建短期有效的上传 URL。

- [ ] 在 iOS 中串联完整生成流程。
  - 创建 job。
  - 上传所有选中帧。
  - 调用 uploads complete。
  - 轮询 job。
  - 下载 `AvatarRecipe`。
  - 跳转头像预览。

- [ ] 接入 OpenAI-compatible 视觉模型。
  - 使用录入帧生成结构化 `AvatarRecipe`。
  - 提示词参考 `docs/avatar-recipe-generation-prompt.md`。

- [ ] 后端校验 `AvatarRecipe` schema。
  - schema 在 `docs/avatar-recipe.schema.json`。
  - 需要拒绝或修复不合法模型输出。

- [ ] 实现原始媒体删除策略。
  - 任务到达 succeeded、failed、expired 等终态后删除原始帧。
  - 保留必要的任务元数据和生成结果。

## P2：本地缓存和离线能力

- [ ] 接入 `AvatarCache`。
  - 当前有保存 / 读取 recipe 的实现，但生成成功后未使用。

- [ ] 缓存头像贴图和模板资源。
  - `AvatarRecipe.Materials` 中有 texture URL。
  - 需要下载、缓存、过期和失败重试策略。

- [ ] 加入 fixture / demo 模式。
  - 当前有 `Preview Fixture` 按钮。
  - 可以保留为无后端演示入口，但要和正式流程分清楚。

## P3：测试和设备验证

- [ ] 添加 iOS 单元测试 target。
  - 覆盖 `AvatarRecipe` 解码。
  - 覆盖 `AvatarJob.Status` 终态判断。
  - 覆盖 `AvatarExpressionMapper` 权重映射和 clamp。
  - 覆盖 `CaptureFrameSelector` 选择最佳帧。
  - 覆盖 `FaceQualityEvaluator` 光照、模糊、姿态评分。

- [ ] 添加 UI 测试。
  - 摄像头权限拒绝。
  - 录入成功。
  - 录入失败和重试。
  - 生成成功。
  - 生成失败。
  - 头像预览加载成功。

- [ ] 做真机矩阵验证。
  - 至少验证 iPhone 12+、iOS 17+。
  - 覆盖室内低光、强背光、眼镜、胡子、长发、不同肤色等情况。

## P3：产品和合规问题

- [ ] 确定后端首版输入格式。
  - 只接受 JPEG 帧，还是也接受短 HEVC 视频。

- [ ] 确定原始录入媒体保留窗口。
  - 需要和隐私策略、产品体验、调试需求一起决定。

- [ ] 确定首个真实视觉模型供应商。
  - 需要选择 OpenAI-compatible provider，并记录成本、延迟和失败率。

- [ ] 评估是否需要年龄门槛或 COPPA 相关处理。
  - 如果面向儿童或可能吸引儿童使用，需要尽早设计合规流程。
