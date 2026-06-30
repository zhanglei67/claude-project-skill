# 状态文件 Schema 参考

`.claude/projects/<name>.yaml` 的完整字段定义、验证规则和最佳实践。

---

## 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | `string` | ✅ | 项目名称，与文件名一致（不含 `.yaml`）。用作 `/project` 的标识 |
| `created` | `date` | ✅ | 创建日期，格式 `YYYY-MM-DD` |
| `context` | `string` | ✅ | 项目背景和关键决策。**每次 `/project` 都会加载（L1）。控制在 200 字以内** |
| `steps` | `Step[]` | ✅ | 步骤列表，按执行顺序排列。支持 DAG 依赖 |
| `sessions` | `Session[]` | ❌ | 会话记录。每次收尾时追加 |

---

## Step 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | `string` | ✅ | 唯一标识，格式 `step-N` 或 `短横线命名`。被 `deps` 引用 |
| `name` | `string` | ✅ | 步骤名称，用于汇报显示 |
| `status` | `enum` | ✅ | `pending`（未开始）\| `in_progress`（进行中）\| `done`（已完成）\| `blocked`（阻塞） |
| `deps` | `string[]` | ✅ | 依赖的步骤 `id` 列表。所有依赖为 `done` 时本步骤才可从 `blocked` 变为可开始 |
| `outputs` | `string[]` | ✅ | 产出文件路径列表（相对项目根目录）。`done` 时 `/project` 会检测文件是否存在 |
| `summary` | `string` | ✅ | 一句话摘要。`done` 时建议填写，作为 L2 上下文注入 |

### status 状态机

```
pending ──→ in_progress ──→ done
   │                           ↑
   └────→ blocked ─────────────┘
            (deps 满足后由 /project 提示解锁)
```

- `blocked` 由用户或 `/project` 根据依赖关系设置
- `blocked → in_progress` 由 `/project` 检测依赖满足后提示，用户确认
- `done` 后不可逆（如需重做，新建步骤或手动编辑 YAML）

---

## Session 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `date` | `date` | ✅ | 日期 `YYYY-MM-DD` |
| `summary` | `string` | ✅ | 本次做了什么 + 产出 + 下次从哪开始。2-3 句话即可 |

---

## 完整示例

```yaml
name: shop-global
created: 2026-06-29
context: |
  电商平台多语言多币种改造。
  决策：i18next+ICU 框架，Stripe+Adyen 支付。
  约束：首屏增量 <200ms，先东南亚后欧洲。

steps:
  - id: step-1
    name: 国际化方案调研
    status: done
    deps: []
    outputs: ["docs/i18n-survey.md"]
    summary: "i18next+ICU 选型，12 个框架对比"

  - id: step-2
    name: 支付渠道整合
    status: done
    deps: []
    outputs: ["docs/payment-integration.md"]
    summary: "Stripe+Adyen 双通道，PCI DSS Level 1"

  - id: step-3
    name: 汇率结算逻辑
    status: blocked
    deps: [step-2]
    outputs: ["docs/fx-settlement.md"]
    summary: ""

  - id: step-4
    name: 架构设计
    status: blocked
    deps: [step-1, step-2, step-3]
    outputs: ["docs/architecture.md"]
    summary: ""

sessions:
  - date: 2026-06-29
    summary: "确认方案，完成第1步（国际化调研）。第2步进行中。下次继续支付整合。"
  - date: 2026-06-30
    summary: "第2步完成。第1步锁定。下次开始第3步汇率结算。"
```

---

## 最佳实践

### 1. context 写法

```yaml
# ✅ 好：精简，有关键决策和约束
context: |
  电商多语言改造。决策：i18next+ICU，Stripe+Adyen。
  约束：首屏增量<200ms，先东南亚后欧洲。

# ❌ 差：太长，每次 /project 都加载浪费 token
context: |
  我们公司成立于2018年，主营跨境电商，目前有120万用户...
  （500字的背景故事）
```

### 2. 命名规范

```yaml
# ✅ 推荐：短横线命名，可读
id: step-1
id: payment-integration
id: perf-benchmark

# ⚠️ 可用但不推荐：太短，语义不清
id: s1
id: p2
```

### 3. 步骤拆解粒度

- 一个步骤 = 一次会话能完成的工作量
- 如果某步产出 > 3 个文件，考虑拆分为多步
- 依赖链太长（>4 步串行）时，检查是否有隐藏的并行机会

### 4. outputs 路径

- 使用相对项目根目录的路径：`docs/specs/architecture.md`
- 不要用 `~` 或绝对路径
- 每步 1-3 个产出文件为宜

### 5. sessions 维护

- 只在「今天就到这」时追加
- 每次 2-3 句话：做了什么 + 产出什么 + 下次从哪开始
- 不要写流水账——这是凝练的抓手，不是对话记录

---

## 验证清单

在保存或修改状态文件前，确认：

- [ ] `name` 与文件名一致？
- [ ] 所有 `deps` 中引用的 `id` 在 `steps` 中存在？
- [ ] 无循环依赖？（`step-1 → step-2 → step-1`）
- [ ] `context` 在 200 字以内？
- [ ] 所有 `done` 步骤的 `outputs` 文件真实存在？
- [ ] `sessions` 最新一条记录是最近一次会话？
