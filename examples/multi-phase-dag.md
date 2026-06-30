# 示例：多阶段项目（复杂 DAG，并行+串行）

一个电商平台的多语言多币种改造项目。7 个步骤，依赖关系形成 DAG——部分步骤可并行，部分必须串行。

## DAG 依赖图

```
第1步 国际化调研 ──────────────────────┐
第2步 支付整合 ──→ 第3步 汇率结算 ────┤  ← 第1、2、4步可并行
第4步 性能测试 ────────────────────────┘
                                       ↓
                               第5步 架构设计（汇聚点）
                                       ↓
                               第6步 技术文档
                                       ↓
                               第7步 分阶段实施
```

- 第 1、2、4 步无依赖 → **可在不同会话中并行推进**
- 第 3 步依赖第 2 步 → **必须等第 2 步完成后解锁**
- 第 5 步依赖第 1、2、3、4 步 → **全部完成后才解锁**
- 第 6 步依赖第 5 步，第 7 步依赖第 6 步 → **严格串行**

## 典型会话编排

```
会话 1（讨论 + 创建）：
  👤: 讨论方向... /project shop-global → 保存计划

会话 2（并行工作 A）：
  👤: /project → 开始第1步（国际化方案调研）

会话 3（并行工作 B）：
  👤: /project → 开始第2步（支付渠道整合）

会话 4（并行工作 C）：
  👤: /project → 开始第4步（性能基准测试）

--- 第1、4步完成，第2步进行中 ---

会话 5（续接第2步）：
  👤: /project → 第2步完成 → 第3步（汇率结算）解锁

会话 6（续接第3步）：
  👤: /project → 第3步完成 → 第5步全部依赖满足

会话 7（汇聚）：
  👤: /project
  🤖: "✅ 第1-4步全部完成，第5步已解锁！需要加载前4步产出吗？"
```

## 状态文件实例

```yaml
name: shop-global
created: 2026-06-29
context: |
  电商平台多语言多币种改造。5个核心方向：
  1. 国际化框架 — 采用 i18next + ICU MessageFormat
  2. 支付渠道 — Stripe + Adyen 双通道，支持 17 种货币
  3. 汇率结算 — 每日固定汇率批次结算，降低波动风险
  4. 性能兜底 — 多语言不增加首屏加载时间（<200ms 增量）
  5. 分阶段上线 — 先东南亚市场，再欧洲，最后拉美
  
  所有文档归拢：docs/specs/global-refactor/

steps:
  - id: step-1
    name: 国际化方案调研
    status: done
    deps: []
    outputs: ["docs/specs/global-refactor/i18n-survey.md"]
    summary: "评估 i18next/react-i18next vs Lingui vs FormatJS，选型 i18next+ICU。产出 12 个框架对比矩阵"

  - id: step-2
    name: 支付渠道整合
    status: done
    deps: []
    outputs: ["docs/specs/global-refactor/payment-integration.md"]
    summary: "Stripe+Adyen 双通道，17种货币，PCI DSS Level 1 合规方案"

  - id: step-3
    name: 汇率+结算逻辑
    status: done
    deps: [step-2]
    outputs: ["docs/specs/global-refactor/fx-settlement.md"]
    summary: "日固定汇率+批次结算，单批次上限 $50K，异常熔断策略"

  - id: step-4
    name: 性能基准测试
    status: done
    deps: []
    outputs: ["docs/specs/global-refactor/perf-benchmark.md"]
    summary: "6种语言×3种设备×4种网络条件的基准数据，i18n bundle <45KB gzip"

  - id: step-5
    name: 架构设计方案
    status: in_progress
    deps: [step-1, step-2, step-3, step-4]
    outputs: ["docs/specs/global-refactor/architecture.md"]
    summary: ""

  - id: step-6
    name: 技术文档+迁移方案
    status: blocked
    deps: [step-5]
    outputs:
      - "docs/specs/global-refactor/tech-spec.md"
      - "docs/specs/global-refactor/migration-plan.md"
    summary: ""

  - id: step-7
    name: 分阶段实施
    status: blocked
    deps: [step-6]
    outputs: []
    summary: ""

sessions:
  - date: 2026-06-29
    summary: "确认5个核心方向+7步计划，建立跨会话协作约定。产出：项目状态文件、首页改造暂缓记录。"
  - date: 2026-06-30
    summary: "完成第1步（国际化调研）和第4步（性能测试）。第2步进行中。下次：继续第2步支付整合讨论，或审阅第1/4步产出后锁定。"
```

## 关键操作演示

### 首次创建
```
👤: /project
🤖: [检测到0个状态文件，但对话中有讨论中的计划]
    "检测到讨论中的计划。保存为？"
👤: shop-global
🤖: [写入 shop-global.yaml] "已保存。7步，第1、2、4步可并行。从第1步开始？"
```

### 中期续接（部分步骤在其他会话完成）
```
👤: /project
🤖: [读 YAML → 检测产出文件]
    "shop-global
     ✅ 第1步 国际化调研 — 产出就绪
     ✅ 第4步 性能测试 — 产出就绪
     🔵 第2步 支付整合 — 进行中
     🔴 第3步 — 等第2步
     🔴 第5步 — 等第1-4步（1、4已就绪，2、3未完成）
     
     下一步：继续第2步支付渠道整合，完成后解锁第3步汇率结算。"
```

### 汇合点（依赖全部满足）
```
👤: /project
🤖: [读 YAML → 检查依赖]
    "shop-global
     ✅ 第1步 ✅ 第2步 ✅ 第3步 ✅ 第4步
     ⚡ 第5步 架构设计 — 所有依赖已满足，可开始！
     
     需要加载前4步的全量产出作为上下文吗？"
```
