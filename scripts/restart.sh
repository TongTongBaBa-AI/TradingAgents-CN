#!/bin/bash
# TradingAgents-CN Docker 重启脚本
# 功能：重启 Docker 服务，可选择是否重新构建
# 使用：./scripts/restart.sh [--build]

set -e

echo "=== TradingAgents-CN Docker 重启脚本 ==="

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "📁 项目目录: $PROJECT_ROOT"

# 清理可能导致模块冲突的空 app 目录
if [ -d "app" ]; then
    FILE_COUNT=$(find app -type f ! -name '.DS_Store' 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "🧹 清理空的 app 目录"
        rm -rf app
    fi
fi

# 解析参数
BUILD_FLAG=""
if [ "$1" == "--build" ] || [ "$1" == "-b" ]; then
    BUILD_FLAG="--build"
    echo "🔄 将重新构建镜像"
fi

# 停止服务
echo "⏹️  停止现有服务..."
docker-compose down

# 启动服务
if [ -n "$BUILD_FLAG" ]; then
    echo "🏗️  重新构建并启动服务..."
    docker-compose up -d --build
else
    echo "🚀 启动服务..."
    docker-compose up -d
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo ""
echo "📊 服务状态:"
docker-compose ps

echo ""
echo "✅ 重启完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Web界面:    http://localhost:8501"
echo "🔴 Redis管理:  http://localhost:8081"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 查看日志: docker-compose logs -f web"
