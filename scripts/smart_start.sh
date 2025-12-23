#!/bin/bash
# TradingAgents-CN 智能Docker启动脚本 (Linux/Mac Bash版本)
# 功能：自动判断是否需要重新构建Docker镜像
# 使用：chmod +x scripts/smart_start.sh && ./scripts/smart_start.sh
# 
# 判断逻辑：
# 1. 清理可能导致模块冲突的空目录
# 2. 检查是否存在tradingagents-cn镜像
# 3. 如果镜像不存在 -> 执行构建启动
# 4. 如果镜像存在但代码有变化 -> 执行构建启动  
# 5. 如果镜像存在且代码无变化 -> 快速启动

set -e

echo "=== TradingAgents-CN Docker 智能启动脚本 ==="
echo "适用环境: Linux/Mac Bash"

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "📁 项目目录: $PROJECT_ROOT"

# 清理可能导致模块冲突的空 app 目录
# chromadb 等库有内部 app.core 模块，空的 app 目录会导致导入冲突
if [ -d "app" ]; then
    # 检查是否为空目录（只有 .DS_Store 或完全为空）
    FILE_COUNT=$(find app -type f ! -name '.DS_Store' | wc -l)
    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "🧹 清理空的 app 目录（防止与 chromadb 模块冲突）"
        rm -rf app
    fi
fi

# 检查是否有镜像
if docker images | grep -q "tradingagents-cn"; then
    echo "✅ 发现现有镜像"
    
    # 检查代码是否有变化
    if git diff --quiet HEAD~1 HEAD -- . ':!*.md' ':!docs/' ':!scripts/' 2>/dev/null; then
        echo "📦 代码无变化，使用快速启动"
        docker-compose up -d
    else
        echo "🔄 检测到代码变化，重新构建"
        docker-compose up -d --build
    fi
else
    echo "🏗️ 首次运行，构建镜像"
    docker-compose up -d --build
fi

echo ""
echo "🚀 启动完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Web界面:    http://localhost:8501"
echo "🔴 Redis管理:  http://localhost:8081"
echo "🍃 Mongo管理:  http://localhost:8082 (需要 --profile management)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 常用命令:"
echo "   查看日志: docker-compose logs -f web"
echo "   停止服务: docker-compose down"
echo "   重启服务: docker-compose restart"
