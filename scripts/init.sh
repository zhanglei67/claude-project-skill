#!/usr/bin/env bash
# ============================================================
# /project Skill — 初始化脚本
# 在目标项目中创建 .claude/projects/ 目录并复制模板
# ============================================================

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-$(pwd)}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  /project Skill — 项目初始化"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查目标目录
if [ ! -d "$TARGET_DIR" ]; then
  echo "✗ 目标目录不存在: $TARGET_DIR"
  exit 1
fi

PROJECTS_DIR="$TARGET_DIR/.claude/projects"
ARCHIVE_DIR="$PROJECTS_DIR/archive"

# 创建目录结构
mkdir -p "$PROJECTS_DIR"
mkdir -p "$ARCHIVE_DIR"

echo "✓ 创建目录结构："
echo "  $PROJECTS_DIR/"
echo "  $ARCHIVE_DIR/"

# 复制模板（如果目标位置不存在）
TEMPLATE_SRC="$SKILL_DIR/templates/project-state.yaml"
TEMPLATE_DST="$PROJECTS_DIR/.template.yaml"

if [ -f "$TEMPLATE_SRC" ]; then
  cp "$TEMPLATE_SRC" "$TEMPLATE_DST"
  echo "✓ 复制模板到 $TEMPLATE_DST"
  echo "  使用模板创建新项目：cp $TEMPLATE_DST $PROJECTS_DIR/<项目名>.yaml"
else
  echo "⚠ 模板文件未找到，跳过。"
fi

# 添加 .gitignore
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
  cat > "$TARGET_DIR/.gitignore" << 'EOF'
# /project Skill — 项目状态文件
.claude/projects/*.yaml
!.claude/projects/.template.yaml
EOF
  echo "✓ 在 .gitignore 中添加项目状态文件（可选提交模板）"
elif ! grep -q ".claude/projects/" "$TARGET_DIR/.gitignore"; then
  cat >> "$TARGET_DIR/.gitignore" << 'EOF'

# /project Skill — 项目状态文件
.claude/projects/*.yaml
!.claude/projects/.template.yaml
EOF
  echo "✓ 在 .gitignore 中追加项目状态文件规则"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  初始化完成！"
echo ""
echo "  使用方式："
echo "    1. 在 Claude Code 中输入 /project"
echo "    2. 按提示创建或续接项目"
echo ""
echo "  更多信息：$SKILL_DIR/README.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
