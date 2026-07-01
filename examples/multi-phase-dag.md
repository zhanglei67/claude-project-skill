# 示例：多阶段项目（复杂 DAG，并行+串行）

一个运行多年的后台管理系统，代码臃肿、维护困难。采用渐进式重构策略，分模块推进。6 个步骤，依赖关系形成 DAG——部分步骤可并行，部分必须串行。

## DAG 依赖图

```
第1步 现状分析+技术选型 ──────────────────┐
第2步 公共组件抽离 ──→ 第5步 状态管理迁移 ──┤
第3步 用户模块迁移 ────────────────────────┤
第4步 数据报表模块迁移 ────────────────────┘
                                            ↓
                                    第6步 全量回归测试
```

- 第 1、2、3、4 步无依赖 → **可在不同会话中并行推进**
- 第 5 步依赖第 2 步 → **必须等第 2 步完成后解锁**
- 第 6 步依赖第 3、4、5 步 → **全部完成后才解锁**

## 典型会话编排

```
会话 1（讨论 + 创建）：
  👤: 讨论重构方案...
  👤: /project
  🤖: "检测到讨论中的计划。为它命名保存？（输入「算了」取消）"
  👤: admin-refactor
  🤖: [保存计划] "admin-refactor 已保存。下次输入 /project 继续。"

会话 2（并行工作 A）：
  👤: /project → 开始第1步（现状分析+技术选型）

会话 3（并行工作 B）：
  👤: /project → 开始第2步（公共组件抽离）

会话 4（并行工作 C）：
  👤: /project → 开始第3步（用户管理模块迁移）

--- 第1、2步完成，第3步进行中 ---

会话 5（续接第4步）：
  👤: /project → 第4步完成 → 第5步等待第2步

会话 6（依赖满足）：
  👤: /project → 第2步完成 → 第5步解锁！

会话 7（汇合）：
  👤: /project
  🤖: "✅ 第1-5步全部完成，第6步已解锁！需要加载前5步产出吗？"
```

## 状态文件实例

```yaml
name: admin-refactor
created: 2026-07-02
context: |
  后台管理系统渐进式重构。
  决策：React 18 + TypeScript 严格模式，Zustand 替代老 Redux。
  约束：不能中断业务，每次只迁移一个模块，上线后观察一周再继续。

steps:
  - id: step-1
    name: 现状分析+技术选型
    status: done
    deps: []
    outputs: ["docs/admin-refactor/analysis.md"]
    summary: "梳理 47 个页面、12 个公共组件。选型：React 18 + Zustand + TS 严格模式"

  - id: step-2
    name: 公共组件抽离
    status: done
    deps: []
    outputs: ["src/components/common/"]
    summary: "抽离 Button/Table/Modal/SearchBar 等 12 个公共组件，编写单元测试"

  - id: step-3
    name: 用户管理模块迁移
    status: done
    deps: []
    outputs: ["src/pages/user/"]
    summary: "用户列表/详情/权限分配 3 个页面迁移完成，API 层统一"

  - id: step-4
    name: 数据报表模块迁移
    status: done
    deps: []
    outputs: ["src/pages/report/"]
    summary: "日报/周报/月报 3 个报表页面迁移，图表库 ECharts→Recharts"

  - id: step-5
    name: 全局状态管理迁移
    status: done
    deps: [step-2]
    outputs: ["src/store/"]
    summary: "老 Redux → Zustand，拆分 userStore/reportStore/commonStore"

  - id: step-6
    name: 全量回归测试
    status: in_progress
    deps: [step-3, step-4, step-5]
    outputs: ["docs/admin-refactor/test-report.md"]
    summary: ""

sessions:
  - date: 2026-07-02
    summary: "确认渐进式重构方案，拆解为 6 步。第 1、2、3、4 步可并行推进。"
  - date: 2026-07-03
    summary: "完成第1步（分析+选型）和第2步（公共组件）。第3步进行中。下次继续第3步。"
  - date: 2026-07-05
    summary: "第3步完成，第4步完成。第5步解锁（第2步已 done）。下次开始第5步。"
```

## 关键操作演示

### 首次创建
```
👤: /project
🤖: [检测到0个状态文件，但对话中有讨论中的计划]
    "检测到讨论中的计划。为它命名保存？"
👤: admin-refactor
🤖: [写入 admin-refactor.yaml] "已保存。6步，第1-4步可并行。从第1步开始？"
```

### 中期续接（部分步骤在其他会话完成）
```
👤: /project
🤖: [扫描 → 1 个活跃项目]
    "加载 admin-refactor（4/6 完成）。
     
     ✅ 第1步 现状分析 — 产出就绪
     ✅ 第2步 公共组件 — 产出就绪
     ✅ 第4步 数据报表 — 产出就绪
     🔵 第3步 用户模块 — 进行中
     🔴 第5步 — 等第2步（第2步已产出，审阅后锁定即可解锁）
     🔴 第6步 — 等第3、4、5步
     
     下一步：继续第3步用户管理模块迁移，或审阅第1、2步产出后锁定。"
```

### 汇合点（依赖全部满足）
```
👤: /project
🤖: [扫描 → 1 个活跃项目]
    "加载 admin-refactor（5/6 完成）。
     
     ✅ 第1步 ✅ 第2步 ✅ 第3步 ✅ 第4步 ✅ 第5步
     ⚡ 第6步 全量回归测试 — 所有依赖已满足，可开始！
     
     需要加载前5步的全量产出作为上下文吗？"
```
