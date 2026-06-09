# Snap Motion

Snap Motion 是一个 iOS 实时拟我头像项目：用户像录入 Face ID 一样转头、眨眼、张嘴，客户端采集多帧自拍视频，后端用 OpenAI-compatible 视觉模型生成结构化 `AvatarRecipe`，iOS 再用 SceneKit 模板 Rig 渲染一个可爱的实时可动头像。

当前仓库重点是技术规划和 iOS 骨架，详见：

- [iOS 技术规划](/Users/endlessovo/dev/ai/snap-motion/docs/ios-technical-plan.md)
- [AvatarRecipe JSON Schema](/Users/endlessovo/dev/ai/snap-motion/docs/avatar-recipe.schema.json)
- [头像生成提示词](/Users/endlessovo/dev/ai/snap-motion/docs/avatar-recipe-generation-prompt.md)
- [iOS 工程骨架](/Users/endlessovo/dev/ai/snap-motion/apps/ios/SnapMotion)

## 第一版范围

第一版建议只做“模板 Rig + AI 生成参数”，不要直接让 AI 生成完整 3D 网格。

包含：

- SwiftUI 录入页、生成进度页、头像预览页。
- ARKit `ARFaceAnchor.blendShapes` 实时表情捕捉。
- SceneKit `SCNMorpher` 驱动眨眼、张嘴、微笑、转头。
- 后端上传录入包、调用视觉模型、返回 `AvatarRecipe`。
- 原始自拍视频或帧图任务完成后删除，只保留头像结果和必要任务元数据。

不包含：

- 账号系统。
- 多端同步。
- AI 直接生成不可控 3D 网格。
- 大规模社交关系链。
- RealityKit 替换渲染管线。

## 成本估算

以下价格按 2026-06-09 查询到的公开价格做估算，只用于立项和定价参考，最终账单以供应商后台为准。

### 固定成本

| 项目 | 估算 |
| --- | ---: |
| Apple Developer Program | $99 / 年 |
| iOS 开发设备 | 至少 1 台支持 TrueDepth 的 iPhone，建议 iPhone 12+ |
| Xcode / SwiftUI / ARKit / SceneKit | 免费 |
| 域名 | 约 $10-$30 / 年，按注册商为准 |

Apple 官方说明 Apple Developer Program 为 $99 / 年；App Store 数字商品抽成通常为 30%，小型企业计划等情形可为 15%。

### 单次头像生成成本

推荐第一版让模型只生成 `AvatarRecipe`，不生成完整 3D 模型。这样一次生成的 AI 成本通常很低。

假设：

- 每次录入上传 8 张关键帧。
- 每张图按 512x512 低分辨率视觉输入估算。
- 输出约 1 个结构化 JSON `AvatarRecipe`。
- 不额外生成 AI 贴图，贴图由模板或简单材质参数完成。

| 模型档位 | 估算单次 AI 成本 | 适合场景 |
| --- | ---: | --- |
| 低成本视觉模型 | $0.005-$0.02 / 次 | MVP、内测、免费额度 |
| 中高质量视觉模型 | $0.02-$0.08 / 次 | 正式生成、付费用户 |
| 加 AI 贴图生成 | 另加约 $0.02-$0.30+ / 次 | 更像本人，但成本和延迟更高 |

OpenAI 官方价格页显示，图像会转成 token 计费；例如价格计算器里 512x512 低分辨率图像示例为 210 tokens。不同模型的每百万 token 价格不同，所以实际费用取决于模型和图像尺寸。

### 月度运行成本

| 阶段 | 月生成量 | 估算月成本 | 说明 |
| --- | ---: | ---: | --- |
| 本地 Demo | 0-100 次 | $0-$10 | 可用 fixture 或少量 API 测试 |
| MVP 内测 | 1,000 次 | $20-$100 | AI + 少量后端 + 存储 |
| 小规模上线 | 10,000 次 | $150-$800 | 重点看模型选择、失败重试率、贴图策略 |
| 增长阶段 | 100,000 次 | $1,500-$8,000+ | 需要缓存、限流、批处理、供应商议价 |

主要变量：

- 每次录入图片数量。
- 图片分辨率。
- 模型档位。
- 是否生成 AI 贴图。
- 失败重试率。
- 原始媒体保留时间。
- 头像资源下载次数。

### 存储和 CDN

第一版建议使用对象存储保存上传帧和生成贴图，并在任务结束后删除原始帧。

Cloudflare R2 适合 MVP，因为它按存储量和操作数收费，并且 R2 直接出站没有额外 egress 费用。官方示例中，R2 Standard 存储 1,000GB 一个月约 $14.85；实际 Snap Motion 只要及时删除原始帧，早期存储成本通常会很低。

### 后端托管

可选方案：

| 方案 | 估算 | 适合场景 |
| --- | ---: | --- |
| 本地 / 单机 VPS | $5-$20 / 月 | 早期调试、低流量 |
| Vercel Hobby | $0 起 | 非商业 demo、Web 管理台 |
| Vercel Pro | $20 / 月 / seat 起 | 小团队、正式 Web/API 辅助服务 |
| Cloudflare Workers + R2 | $0-$30+ / 月起 | 上传签名、轻量任务 API |

如果后端需要长任务队列、重试、任务状态机和更强日志，建议单独使用队列服务和数据库，不要把所有生成逻辑塞进一个无状态函数。

## 推荐产品定价

### 方案 A：免费试用 + 内购头像

| 套餐 | 建议价格 | 内容 |
| --- | ---: | --- |
| 免费 | $0 | 1 个基础头像，有限重生成 |
| 单个头像重生成 | $0.99-$2.99 | 重新生成一次 `AvatarRecipe` |
| 高级头像包 | $4.99-$9.99 | 多次生成、更细贴图、更完整配饰 |

适合先验证用户是否愿意为“像自己、可动、可爱”的效果付费。

### 方案 B：订阅

| 套餐 | 建议价格 | 内容 |
| --- | ---: | --- |
| Free | $0 | 1 个头像，基础预览 |
| Plus | $2.99-$4.99 / 月 | 每月 5-20 次重生成，高级发型和配饰 |
| Creator | $9.99-$14.99 / 月 | 高频生成、导出视频、更多模板 |

订阅更适合后续加入短视频导出、直播虚拟形象、社交玩法之后再推。

### 方案 C：B2B SDK

| 套餐 | 建议价格 | 内容 |
| --- | ---: | --- |
| Starter | $99-$299 / 月 | 小应用接入，有限生成量 |
| Growth | $499-$1,999 / 月 | 更高额度、品牌模板、基础 SLA |
| Enterprise | 定制 | 私有化、专属模型、合规支持 |

如果 Snap Motion 未来不只做 App，也可以把 `AvatarRecipe` 生成和实时头像驱动包装成 SDK。

## 毛利粗算

以一次头像生成成本 $0.02-$0.08 估算：

| 售价 | App Store 15% 后收入 | App Store 30% 后收入 | 生成成本后大致空间 |
| ---: | ---: | ---: | --- |
| $0.99 | $0.84 | $0.69 | 仍可覆盖多次低成本生成 |
| $2.99 | $2.54 | $2.09 | 适合作为单次高级生成 |
| $4.99 | $4.24 | $3.49 | 可覆盖贴图、更高模型和重试 |

结论：第一版只生成结构化 recipe 时，AI 成本不是最大压力。真正的成本压力通常来自获客、审核合规、3D 资产质量、失败重试、用户反复重生成，以及后续视频导出算力。

## MVP 预算建议

最小可行预算：

- Apple Developer Program：$99 / 年。
- API 测试预算：$20-$100。
- 后端和存储：$0-$30 / 月。
- 一台 iPhone 12+ 真机。

建议先把每月 API 预算上限设为 $50-$100，等真实生成成功率、平均 token、平均重试次数稳定后，再扩大内测人数。

## 省钱策略

- 每次只上传精选关键帧，不上传长视频。
- 图片先在客户端压缩到足够清晰的尺寸。
- 先生成 `AvatarRecipe`，不要第一版就生成完整 3D 网格。
- 用低成本模型做初稿，高质量模型只用于付费生成或失败修复。
- 对失败任务做最多 1 次 schema 修复，不无限重试。
- 原始帧任务完成后立即删除。
- 用模板贴图和参数材质覆盖大多数用户，不默认跑 AI 贴图。
- 给免费用户设置生成次数上限。

## 价格来源

- [OpenAI API Pricing](https://openai.com/api/pricing/)
- [Apple Developer Program Membership Details](https://developer.apple.com/programs/whats-included/)
- [Cloudflare R2 Pricing](https://developers.cloudflare.com/r2/pricing/)
- [Vercel Pricing Docs](https://vercel.com/docs/pricing)
