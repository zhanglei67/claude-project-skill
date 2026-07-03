# 示例：多阶段项目（DAG + 断点续接 + 暗号操作）

后台管理系统渐进式重构。6 个步骤，有依赖、有并行。演示完整的暗号操作流程。

## DAG 依赖图

```
第1步 现状分析+技术选型 ──────────────────┐
第2步 公共组件抽离 ──→ 第5步 状态管理迁移 ──┤
第3步 用户模块迁移 ────────────────────────┤
第4步 数据报表模块迁移 ────────────────────┘
                                           ↓
                                   第6步 全量回归测试
```

- 第 1、2、3、4 步无依赖 → 可并行推进
- 第 5 步依赖第 2 步 → 第 2 步完成后解锁
- 第 6 步依赖第 3、4、5 步 → 全部完成后解锁

## 会话编排（暗号操作）

```
会话 1（讨论 + 创建）：
  👤: 讨论重构方案……
  👤: /project
  🤖: [检测到计划] "为它命名保存？"
  👤: admin-refactor
  🤖: [保存 + 菜单]
       ──────────────────────────────
        继续 N  │  完成 N  │  保存 N
       ──────────────────────────────

会话 2（第1步工作中保存断点）：
  👤: /project → 继续 1 → 工作……
  👤: /project → 保存 1
  🤖: [审视对话 → 提炼断点 → 确认 → 保存]

会话 3（断点续接 + 完成）：
  👤: /project
  🤖: "🔵 第1步 断点：✅ 30/47页面 ⬜ 17页面+选型"
  👤: 继续 1 → [断点注入] → 工作…… → /project → 完成 1
  🤖: "✅ 第1步完成"

会话 4（并行推进）：
  👤: /project → 继续 2 → 工作…… → /project → 完成 2
  🤖: "✅ 第2步完成。⚡ 第5步已解锁！"

会话 5（跨多天的大步骤，多次保存）：
  👤: /project → 继续 3 → 工作（列表页完成）→ /project → 保存 3
  🤖: [断点：✅ 列表页 ⬜ 详情页/权限]
  
  --- 第二天 ---
  👤: /project → 继续 3 → [断点注入] → 工作（详情页完成）→ /project → 保存 3
  🤖: [断点更新：✅ 列表页+详情页 ⬜ 权限/批量操作]
  
  --- 第三天 ---
  👤: /project → 继续 3 → [断点注入] → 工作…… → /project → 完成 3
  🤖: "✅ 第3步完成。checkpoint 已清除"

会话 6（汇合 + 完成）：
  👤: /project → 继续 4 → 工作…… → /project → 完成 4
  👤: /project → 继续 5 → 工作…… → /project → 完成 5
  👤: /project → 继续 6 → 工作…… → /project → 完成 6
  🤖: "🎉 admin-refactor 全部完成！6/6 步骤已全部完成。"
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
    summary: "梳理 47 个页面、12 个公共组件。选型 React 18 + Zustand + TS 严格模式"

  - id: step-2
    name: 公共组件抽离
    status: done
    deps: []
    outputs: ["src/components/common/"]
    summary: "抽离 Button/Table/Modal/SearchBar 等 12 个公共组件，编写单元测试"

  - id: step-3
    name: 用户管理模块迁移
    status: in_progress
    deps: []
    outputs: ["src/pages/user/"]
    summary: ""
    checkpoint:
      done: |
        - 用户列表页 UI（搜索框 + 分页组件）
        - GET /users API 对接
      remaining: |
        - 用户详情页（UI + GET /users/:id）
        - 权限分配页面
        - 批量操作（启用/禁用）
      notes: |
        - API 返回格式从 {data, total} 改成了 {items, count}，需统一适配

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
    status: pending
    deps: [step-3, step-4, step-5]
    outputs: ["docs/admin-refactor/test-report.md"]
    summary: ""

sessions:
  - date: 2026-07-02
    summary: "确认渐进式重构方案，拆解 6 步。第 1-4 步可并行。"
  - date: 2026-07-03
    summary: "第 1 步和第 2 步完成。第 3 步用户模块进行中——列表页完成，详情页和权限待做。"
```

## 关键操作演示

### 保存断点（`保存 N`）
```
👤: /project

🤖: [进度 + 菜单]

👤: 保存 3

🤖: [审视对话]
    "第3步 用户管理模块迁移 — 根据本次会话进展整理：
     
     ✅ 已完成
     · 列表页 UI（搜索框 + 分页组件）
     · GET /users API 对接
     
     ⬜ 待完成
     · 用户详情页
     · 权限分配页面
     
     ⚠️ 注意
     · API 返回格式改了：{data, total} → {items, count}
     
     有要改的吗？"
👤: 确认
🤖: [写入 checkpoint + session 记录]
    "断点已保存。下次 /project 后选「继续 3」从断点续接。"
```

### 断点续接（`继续 N`）
```
👤: /project

🤖: "加载 admin-refactor（2/6 完成）。
     
     ✅ 第1步 现状分析 — 梳理47个页面，选型 React 18 + Zustand
     ✅ 第2步 公共组件 — 抽离12个组件，单元测试完成
     🔵 第3步 用户模块 — 进行中
       断点：✅ 列表页 UI + API
            ⬜ 详情页、权限分配、批量操作
     
     ──────────────────────────────
      继续 N  │  完成 N  │  保存 N
     ──────────────────────────────"

👤: 继续 3

🤖: [注入 checkpoint 为工作上下文]
    "🔵 第3步 — 上次断点
    
     ✅ 已完成：列表页 UI + GET /users API
     ⬜ 待完成：详情页、权限分配、批量操作
     ⚠️ 注意：API 返回格式从 {data, total} 改成了 {items, count}
     
     从断点继续。收尾时用「保存 3」更新断点。"
```

### 全部完成
```
👤: /project
👤: 完成 6

🤖: [检测产出 → 标记 done → 清除 checkpoint → 全部完成]
    
    🎉 admin-refactor 全部完成！
    
    6/6 步骤已全部完成。
    状态文件保留在 .claude/projects/admin-refactor.yaml
    输入「归档」将项目移入 archive/。
```
