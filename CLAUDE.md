# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TradingAgents-CN is a Chinese-enhanced multi-agent LLM-based stock analysis framework. It's a fork of TradingAgents with extensive Chinese market support (A-shares, Hong Kong stocks), domestic LLM integration (DashScope/Qwen, DeepSeek, Qianfan/ERNIE), and a complete Streamlit web interface.

**Version**: 0.1.15 (cn-0.1.15)

## Build and Development Commands

### Installation and Setup

```bash
# Install dependencies (recommended method)
pip install -e .

# Or using uv (faster)
uv pip install -e .

# Upgrade pip first (important to avoid installation errors)
python -m pip install --upgrade pip
```

### Running the Application

```bash
# Start web interface (primary method)
python start_web.py

# Or directly with streamlit
streamlit run web/app.py

# Start with Docker (includes MongoDB and Redis)
docker-compose up -d --build    # First time or after code changes
docker-compose up -d            # Daily start
```

### Testing

```bash
# Run installation validation
python examples/test_installation.py

# Test specific LLM providers
python examples/dashscope_examples/demo_dashscope_simple.py
python examples/demo_deepseek_simple.py

# System status check
python scripts/validation/check_system_status.py
```

### Useful Development Scripts

```bash
# Initialize database
python scripts/setup/init_database.py

# User management
python scripts/user_password_manager.py list
python scripts/user_password_manager.py change-password <username>

# Cache cleanup
python scripts/maintenance/cleanup_cache.py --days 7
```

## High-Level Architecture

### Multi-Agent System Architecture

The system uses LangGraph to orchestrate multiple specialized agents:

1. **Analyst Layer** (tradingagents/agents/analysts/)
   - Market Analyst: Technical analysis and price trends
   - Fundamentals Analyst: Financial metrics and company health
   - News Analyst: News sentiment and events analysis
   - Social Media Analyst: Social media sentiment (Reddit, etc.)

2. **Research Layer** (tradingagents/agents/researchers/)
   - Bull Researcher: Arguments for buying
   - Bear Researcher: Arguments for selling
   - These engage in structured debates to challenge assumptions

3. **Decision Layer** (tradingagents/agents/trader/)
   - Trader: Final investment decision based on all analyses
   - Risk Manager: Multi-layer risk assessment

4. **Management Layer** (tradingagents/agents/managers/)
   - Research Manager: Coordinates research workflow
   - Risk Manager: Oversees risk assessment

### Data Flow Architecture

**Data Sources** (tradingagents/dataflows/):
- Chinese Markets: Tushare (primary), AKShare, TongDaXin API
- HK Markets: AKShare, Yahoo Finance
- US Markets: FinnHub, Yahoo Finance
- News: Google News, unified news retrieval

**Caching Strategy** (multi-layer fallback):
1. Redis cache (in-memory, fastest)
2. MongoDB cache (persistent)
3. Direct API calls (TongDaXin, Tushare, etc.)
4. Local file cache (backup)

**Key Implementation**: `tradingagents/dataflows/interface.py` provides unified data access interface with automatic fallback.

### LLM Integration Architecture

**Supported Providers** (tradingagents/llm_adapters/):
- **DeepSeek** (Recommended): `ChatDeepSeek` (direct adapter) - Default choice for best cost-performance
- DashScope (Alibaba Qwen): `ChatDashScope`, `ChatDashScopeOpenAI`
- Google AI: `ChatGoogleOpenAI` (OpenAI-compatible adapter)
- Qianfan (Baidu ERNIE): OpenAI-compatible endpoint
- OpenRouter: Aggregates 60+ models
- Native OpenAI: Custom endpoint support

**Adapter Pattern**: All LLM adapters inherit from OpenAI-compatible base to ensure consistent tool calling and streaming support.

**Default Configuration**: Set via `DEFAULT_CONFIG` in `tradingagents/default_config.py`:
```python
config = {
    "llm_provider": "deepseek",         # Recommended default (not dashscope/qwen)
    "deep_think_llm": "deepseek-chat",  # For complex reasoning
    "quick_think_llm": "deepseek-chat", # For simple tasks
}
```

**Alternative Configurations**:
```python
# DashScope/Qwen (if specifically needed)
config = {
    "llm_provider": "dashscope",
    "deep_think_llm": "qwen-plus",
    "quick_think_llm": "qwen-turbo",
}
```

### Web Application Architecture

**Entry Point**: `web/app.py` (Streamlit application)

**Key Components** (web/components/):
- `sidebar.py`: Model selection, API configuration
- `analysis_form.py`: Stock input and research depth selection
- `async_progress_display.py`: Real-time analysis progress
- `results_display.py`: Analysis results and report export
- `login.py`: User authentication (admin/user roles)

**Session Management**: Uses `st.session_state` for persistence, with URL parameters for sharing configurations.

**User Authentication**: Basic role-based system (admin/user) with activity logging to MongoDB.

## Project Structure Highlights

```
tradingagents/
├── agents/           # Multi-agent implementations
│   ├── analysts/     # Market, fundamentals, news, social media
│   ├── researchers/  # Bull/bear debate agents
│   ├── trader/       # Final decision maker
│   └── managers/     # Coordination and risk management
├── dataflows/        # Data source integrations
│   ├── interface.py  # Unified data access with fallback
│   ├── tushare_utils.py
│   ├── akshare_utils.py
│   └── cache_manager.py
├── llm_adapters/     # LLM provider adapters
├── graph/            # LangGraph workflow orchestration
│   ├── trading_graph.py    # Main graph orchestrator
│   ├── conditional_logic.py
│   └── propagation.py
├── config/           # Configuration management
└── utils/            # Utilities (logging, news filtering, etc.)

web/
├── app.py           # Main Streamlit application
├── components/      # UI components
└── utils/           # Web-specific utilities

scripts/
├── setup/           # Installation and initialization
├── validation/      # System validation and testing
└── maintenance/     # Cleanup and maintenance tools
```

## Important Configuration Details

### Environment Variables

Key variables in `.env`:

```bash
# LLM API Keys (at least one required)
DEEPSEEK_API_KEY=sk-xxx           # DeepSeek (RECOMMENDED - best cost-performance)
DASHSCOPE_API_KEY=sk-xxx          # Alibaba DashScope/Qwen (alternative)
GOOGLE_API_KEY=xxx                # Google AI (alternative)
QIANFAN_ACCESS_KEY=xxx            # Baidu Qianfan (alternative)
QIANFAN_SECRET_KEY=xxx

# Data APIs
FINNHUB_API_KEY=xxx               # US market data (required for US stocks)
TUSHARE_TOKEN=xxx                 # A-share data (optional but recommended)

# Database (optional, improves performance)
MONGODB_ENABLED=true
MONGODB_HOST=localhost            # Use 'mongodb' for Docker
REDIS_ENABLED=true
REDIS_HOST=localhost              # Use 'redis' for Docker

# Feature Flags
ONLINE_TOOLS_ENABLED=false        # Enable real-time tools
ONLINE_NEWS_ENABLED=true          # Enable news retrieval
MEMORY_ENABLED=false              # ChromaDB memory (disable on Windows 10)
```

### Research Depth Levels

The system supports 5 research depth levels (configured in web interface):

1. **Level 1** (2-4 min): Quick technical analysis
2. **Level 2** (4-6 min): Standard analysis
3. **Level 3** (6-10 min): Deep analysis with news (recommended)
4. **Level 4** (10-15 min): Full analysis with debate rounds
5. **Level 5** (15-25 min): Most comprehensive analysis

Depth affects `max_debate_rounds` and `max_risk_discuss_rounds` in configuration.

### Stock Code Formats

- **A-shares**: 6 digits (e.g., 000001, 600519)
- **HK stocks**: 4 digits + .HK (e.g., 0700.HK, 9988.HK)
- **US stocks**: Ticker symbols (e.g., AAPL, TSLA)

## Key Implementation Patterns

### Data Source Fallback Pattern

When retrieving data, always use the unified interface which implements automatic fallback:

```python
from tradingagents.dataflows.interface import get_stock_data

# Automatically tries: Redis -> MongoDB -> API -> Local cache
data = get_stock_data(ticker, start_date, end_date)
```

### LLM Tool Calling Pattern

All agents use LangChain's tool calling pattern. When adding new tools:

1. Define tool function with proper docstring
2. Bind tools to LLM: `llm.bind_tools([tool1, tool2])`
3. Handle tool calls in agent logic
4. Use ToolNode for automatic tool execution in graph

### News Filtering Pattern

The system has intelligent news filtering (v0.1.12+):

```python
from tradingagents.utils.enhanced_news_filter import EnhancedNewsFilter

filter = EnhancedNewsFilter(llm)
filtered_news = filter.filter_news(news_list, ticker)
```

Three filtering levels: basic, enhanced, integrated.

### Logging Pattern

Use the unified logging system:

```python
from tradingagents.utils.logging_manager import get_logger

logger = get_logger('module_name')
logger.info("Message")
```

Logs go to `logs/` directory with structured format.

## Common Gotchas

1. **ChromaDB Windows 10 Issue**: Set `MEMORY_ENABLED=false` in `.env` on Windows 10 due to ChromaDB compatibility issues.

2. **Module Import**: Always install with `pip install -e .` to make `tradingagents` package importable.

3. **Database Hosts**: In Docker, use `mongodb` and `redis` as hostnames. In local deployment, use `localhost`.

4. **API Rate Limits**: The system implements caching to reduce API calls. Check cache settings if hitting rate limits.

5. **Progress Display**: Web interface uses async progress tracking with WebSocket-like updates via `st.session_state`.

6. **Model Selection Persistence**: Model selections are persisted in URL parameters for shareable configurations.

## Testing and Validation

When making changes:

1. Run `python examples/test_installation.py` to verify core functionality
2. For LLM changes, test with a simple analysis: `python examples/demo_deepseek_simple.py` (recommended) or `python examples/dashscope_examples/demo_dashscope_simple.py`
3. For web changes, test with local Streamlit instance: `python start_web.py`
4. Check system status: `python scripts/validation/check_system_status.py`

## Recent Major Changes (v0.1.15)

- Qianfan (Baidu ERNIE) LLM integration with OpenAI-compatible adapter
- LLM adapter architecture refactoring for consistency
- Enhanced LLM integration documentation and testing tools
- TradingAgents paper Chinese translation and academic materials

## Documentation

Extensive Chinese documentation in `docs/`:
- Architecture: `docs/architecture/`
- Agents: `docs/agents/`
- Configuration: `docs/configuration/`
- Examples: `docs/examples/`
- FAQ: `docs/faq/faq.md`

Total: 50,000+ words, 20+ documents, 100+ code examples.
