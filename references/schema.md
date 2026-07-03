# 状态文件 Schema 参考

`.claude/projects/<name>.yaml` 的完整字段定义、验证规则和最佳实践。

---

## 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | `string` | ✅ | 项目名称，与文件名一致（不含 `.yaml`） |
| `created` | `date` | ✅ | 创建日期，格式 `YYYY-MM-DD` |
| `context` | `string` | ✅ | 项目背景和关键决策。**每次 `/project` 都会加载（L1）。控制在 200 字以内** |
| `steps` | `Step[]` | ✅ | 步骤列表，按执行顺序排列。支持 DAG 依赖 |
| `sessions` | `Session[]` | ❌ | 会话记录。「保存 N」时追加 |

---

## Step 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | `string` | ✅ | 唯一标识，格式 `step-N` 或 `短横线命名`。被 `deps` 引用 |
| `name` | `string` | ✅ | 步骤名称，用于汇报显示 |
| `status` | `enum` | ✅ | `pending` \| `in_progress` \| `done` \| `blocked` |
| `deps` | `string[]` | ✅ | 依赖的步骤 `id` 列表。所有依赖为 `done` 时本步骤才可开始 |
| `outputs` | `string[]` | ✅ | 产出文件路径列表。`完成 N` 时检测文件是否存在。可以为空数组 `[]` |
| `summary` | `string` | ✅ | 一句话摘要。`完成 N` 时填写，作为 L2 上下文注入 |
| `checkpoint` | `Checkpoint` | ❌ | **仅 `in_progress` 时存在**。`保存 N` 创建，`完成 N` 自动清除 |

### Checkpoint 子字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `done` | `string` | ✅ | 已完成的具体事项，分点列表。「保存 N」时从对话提取 |
| `remaining` | `string` | ✅ | 待完成的具体事项。下次「继续 N」时注入为工作议程 |
| `notes` | `string` | ❌ | 过程中发现的问题、决策、踩坑。无内容则不写 |

### 字段生命周期

```
pending ──→ in_progress ──→ done
                │                │
                │ checkpoint     │ checkpoint 清除
                │ ← 「保存 N」    │ summary 写入
                │                 │ outputs 锁定
                │                 │
                └── 多次会话 ────┘
                   「继续 N」注入断点
                   「保存 N」更新断点
```

- **checkpoint**：步骤内部的状态序列化。`保存 N` 创建/更新，`完成 N` 清除
- **summary**：步骤完成后的结项摘要。`完成 N` 时写入
- **outputs**：最终交付物。`完成 N` 时验证

### status 状态机

```
pending ──→ in_progress ──→ done
   │            ↑              ↑
   └────→ blocked ────────────┘
            (deps 满足后解锁)
```

- `blocked` 根据依赖关系设置
- `继续 N` 将 `pending` 或 `blocked`（依赖满足）→ `in_progress`
- `pending → done` 允许跳过 `in_progress`（用户可能直接 `完成 N`）
- `done` 后不可逆

---

## Session 字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `date` | `date` | ✅ | 日期 `YYYY-MM-DD` |
| `summary` | `string` | ✅ | 本次做了什么 + 产出 + 下次从哪开始。2-3 句话 |

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
    status: in_progress
    deps: []
    outputs: ["src/pages/user/"]
    checkpoint:
      done: |
        - 用户列表页 UI（搜索框 + 分页组件）
        - GET /users API 对接
      remaining: |
        - 用户详情页（UI + GET /users/:id）
        - 权限分配页面
        - 批量操作（启用/禁用）
      notes: |
        - API 返回格式从 {data, total} 改成了 {items, count}

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
    summary: "确认渐进式重构方案，6 步拆解。第 1-4 步可并行。"
  - date: 2026-07-03
    summary: "第 1 步和第 2 步完成。第 3 步用户模块进行中——列表页完成，详情页和权限分配待做。"
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
  我们公司成立于2018年，主营电商，目前有120万用户……（500 字背景故事）
```

### 2. 步骤拆解粒度

- 一个步骤 = 一次会话能完成的工作量
- 如果某步产出 > 3 个文件，考虑拆分为多步
- 依赖链太长（>4 步串行）时，检查是否有隐藏的并行机会

### 3. outputs 路径

- 使用相对项目根目录的路径
- 每步 1-3 个产出文件为宜
- outputs 可以为空数组 `[]`（纯调研/讨论步骤）

### 4. checkpoint 写法

- **done/remaining 用分点列表**，每点一句话
- **只写具体事项**，不写模糊描述
  - ✅ "列表页查询性能优化，从 2s 降到 200ms"
  - ❌ "做了一些优化"
- **remaining 保持可操作**——下次「继续 N」能直接当工作议程
- **notes 只记有用的**：踩坑、API 变更、未决问题
- **控制在 300 字以内**。步骤完成即清除，不是永久文档

```yaml
# ✅ 好：具体、可操作
checkpoint:
  done: |
    - 列表页 UI（搜索框 + 分页）
    - GET /users API 对接
  remaining: |
    - 用户详情页（UI + GET /users/:id）
    - 权限分配页面
  notes: |
    - API 返回格式改了：{data, total} → {items, count}

# ❌ 差：模糊、不可操作
checkpoint:
  done: |
    - 做了一些前端工作
  remaining: |
    - 继续开发
```

---

## 验证清单

- [ ] `name` 与文件名一致
- [ ] 所有 `deps` 引用的 `id` 在 `steps` 中存在
- [ ] 无循环依赖（`step-1 → step-2 → step-1`）
- [ ] `context` 在 200 字以内
- [ ] 所有 `done` 步骤的 `outputs` 文件真实存在
- [ ] `in_progress` 步骤的 `checkpoint` 内容来自用户确认
- [ ] `done` 步骤的 `checkpoint` 已清除
- [ ] `sessions` 最新记录是最近一次会话
