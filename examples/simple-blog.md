# 示例：博客系统开发（简单线性项目）

## 会话 1：讨论 + 生成计划

```
👤: "帮我做个 Markdown 博客，Next.js + Vercel，支持代码高亮"

🤖: [讨论技术选型...]

    建议分 4 步：
    1. 项目初始化 + 基础架构
    2. 文章渲染（Markdown → HTML + 代码高亮）
    3. 样式 + 响应式
    4. 部署到 Vercel

    预计 2-3 次会话。确认？

👤: 确认，/project myblog

🤖: myblog 已保存。从第 1 步开始？
👤: 开始
🤖: [创建项目...]
```

## 会话 2：续接

```
👤: /project

🤖: "myblog · 进行中
     ✅ 第1步 项目初始化（产出：Next.js 项目骨架）
     ⚡ 第2步 文章渲染（可开始）
     🔴 第3步（等第2步）
     🔴 第4步（等第3步）
     
     从第2步开始？"

👤: 继续第2步
🤖: [实现 Markdown 渲染...]
```

## 对应的状态文件

```yaml
name: myblog
created: 2026-06-30
context: |
  Markdown 博客系统。Next.js + Vercel + rehype 代码高亮。
  决策：用 gray-matter 解析 frontmatter，不引入 CMS。
steps:
  - id: step-1
    name: 项目初始化
    status: done
    deps: []
    outputs: ["myblog/"]
    summary: "Next.js 项目骨架，page router，基础 Layout"
  - id: step-2
    name: 文章渲染
    status: done
    deps: [step-1]
    outputs: ["src/lib/markdown.ts"]
    summary: "gray-matter + rehype-highlight，支持 frontmatter + 代码高亮"
  - id: step-3
    name: 样式 + 响应式
    status: in_progress
    deps: [step-2]
    outputs: []
    summary: ""
  - id: step-4
    name: Vercel 部署
    status: blocked
    deps: [step-3]
    outputs: []
    summary: ""
sessions:
  - date: 2026-06-30
    summary: "完成了第1步（项目初始化）和第2步（markdown渲染）。下次从第3步（样式）开始。"
  - date: 2026-07-01
    summary: "第3步进行中：完成了导航栏和文章页的响应式布局。继续第3步的首页和列表页。"
```
