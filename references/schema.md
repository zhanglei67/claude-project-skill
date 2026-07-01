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
name: admin-refactor
created: 2026-07-02
context: |
  后台管理系统渐进式重构。
  决策：React 18 + TypeScript 严格模式，Zustand 替代老 Redux。
  约束：不能中断业务，每次只迁移一个模块。

steps:
  - id: step-1
    name: 现状分析+技术选型
    status: done
    deps: []
    outputs: ["docs/admin-refactor/analysis.md"]
    summary: "梳理 47 个页面，12 个公共组件。选型 React 18 + Zustand"

  - id: step-2
    name: 公共组件抽离
    status: done
    deps: []
    outputs: ["src/components/common/"]
    summary: "抽离 12 个公共组件，编写单元测试"

  - id: step-3
    name: 用户管理模块迁移
    status: done
    deps: []
    outputs: ["src/pages/user/"]
    summary: "用户列表/详情/权限分配 3 页面迁移完成"

  - id: step-4
    name: 数据报表模块迁移
    status: blocked
    deps: []
    outputs: ["src/pages/report/"]

  - id: step-5
    name: 全局状态管理迁移
    status: blocked
    deps: [step-2]
    outputs: ["src/store/"]

  - id: step-6
    name: 全量回归测试
    status: blocked
    deps: [step-3, step-4, step-5]
    outputs: ["docs/admin-refactor/test-report.md"]

sessions:
  - date: 2026-07-02
    summary: "确认渐进式重构方案，6 步拆解。第 1-4 步可并行。下次从第 1 步开始。"
  - date: 2026-07-03
    summary: "第 1 步（分析+选型）完成。第 2 步（公共组件）进行中。下次继续第 2 步。"
```

---

## 最佳实践

### 1. context 写法

```yaml
# ✅ 好：精简，有关键决策和约束
context: |
  后台管理系统重构。决策：React 18 + Zustand。
  约束：不能中断业务，每次只迁移一个模块。

# ❌ 差：太长，每次 /project 都加载浪费 token
context: |
  我们公司成立于2018年，主营电商，目前有120万用户，
  后台系统是2019年用 Vue2 写的……（500 字的背景故事）
```

### 2. 命名规范

```yaml
# ✅ 推荐：短横线命名，可读
id: step-1
id: component-extraction
id: state-migration

# ⚠️ 可用但不推荐：太短，语义不清
id: s1
id: p2
```

### 3. 步骤拆解粒度

- 一个步骤 = 一次会话能完成的工作量
- 如果某步产出 > 3 个文件，考虑拆分为多步
- 依赖链太长（>4 步串行）时，检查是否有隐藏的并行机会

### 4. outputs 路径

- 使用相对项目根目录的路径：`docs/admin-refactor/analysis.md`
- 不要用 `~` 或绝对路径
- 每步 1-3 个产出文件为宜
- outputs 可以为空数组 `[]`（纯调研/讨论步骤不需要产出文件）

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
