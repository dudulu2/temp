# Agent Observatory

本地 **Codex/Astra + AGY + Sol/Agentify** 实时旁路观测台。

当前版本：**v0.2.0**

## 它解决什么问题

首页直接看三类 Agent 在滚动时间窗口里的工作量：

| Agent | 1 小时 | 3 小时 | 6 小时 | 24 小时 |
| --- | ---: | ---: | ---: | ---: |
| Astra / Codex | exact | exact | exact | exact |
| AGY | reported（日志提供时） | reported | reported | reported |
| Sol | ~visible estimate | ~visible estimate | ~visible estimate | ~visible estimate |

还会显示：

- Astra 的 Input / Cached / Output / Reasoning；
- AGY 调用次数、耗时，以及能从 AGY 日志取得的 usage；
- Sol/Agentify 调用次数、耗时、可见输入/输出估算；
- 两套 Codex 客户端（`.codex` 与 `.codex-vscode-official`）的 Astra Token 分布；
- 最近调用时间线；
- 数据源是否找到、是否正常监听。

## 最重要的设计：Live-only，启动不导入历史

Observatory **不会在启动时把过去几天/几 GB 的日志读进数据库**。

启动流程是：

1. HTTP Dashboard 先启动；
2. 后台只遍历文件名/文件大小，给已存在日志记录当前 EOF offset；
3. **不读取旧日志内容，不产生历史 Token 事件**；
4. Windows 使用 `ReadDirectoryChangesW` 等待文件变化；
5. 以后只读取 EOF 后新增的字节；
6. SQLite 只保存小型 Token/调用增量记录。

因此第一次启动时 1h/3h/6h/24h 都会从 0 开始逐步积累，这是预期行为。

Observatory 停止期间产生的 Token **不会在下次启动时回补**。这是故意的：优先保证旁路、低影响，而不是做历史 ETL。

## 不进入 Codex 执行链

- 不修改 Codex；
- 不修改 `AGENTS.md`；
- 不用 wrapper 包住 `agy.exe`；
- 不代理 MCP；
- 不向 Sol 发送额外请求；
- Agentify `/status` 轮询默认关闭；
- Windows 下 Observatory 自身进程优先级降为 `Below Normal`；
- 只写自己的 `data/observatory.db`。

## 一键启动

1. 安装 Python 3.11+；
2. 双击 `START.bat`；
3. 浏览器打开 `http://127.0.0.1:8755`。

后台运行：`START_BACKGROUND.bat`  
不自动打开网页：`START_NO_BROWSER.bat`  
停止：`STOP.bat`  
自检：`SELF_TEST.bat`

第一次启动自动生成 `config.json`，使用当前 Windows 用户目录，不需要手填 `yemuy`。

## 默认数据源

### Codex / Astra

默认监听：

- `%USERPROFILE%\.codex\sessions`
- `%USERPROFILE%\.codex-vscode-official`
- `%USERPROFILE%\.codex`

`.codex` 与 `.codex\sessions` 会自动去掉重复递归监听；`.codex-vscode-official` 独立保留。

当前 rollout 有 `token_usage_record` 时，按 response 记录真实：

- input tokens
- cached input tokens
- output tokens
- reasoning output tokens

旧格式只有累计 `token_count` 时，用增量计算，并处理 `last_token_usage` / exact record 的去重。

### AGY

默认只监听可能的 state/log 目录，不递归扫描 AGY 安装目录：

- `%USERPROFILE%\.agy`
- `%LOCALAPPDATA%\agy\logs`
- `%LOCALAPPDATA%\agy\history`
- `%APPDATA%\agy\logs`

即使 AGY 没有自己的 usage 日志，Observatory 仍可从 Codex rollout 识别 `agy.exe` 调用和大致耗时；拿不到 Token 就显示为空，不伪造。

### Sol / Agentify

从 Codex rollout 中识别 `agentify_query`，记录：

- 调用次数；
- duration；
- prompt 可见 Token 估算；
- `packedContextSummary.contextCharsUsed` 的上下文估算；
- 网页返回文本的可见 Token 估算；
- 成功/失败（日志可得时）。

ChatGPT 网页不公开隐藏 reasoning token，因此 Sol 永远标为 **ESTIMATED VISIBLE**。

## Agentify API 默认零轮询

```json
"agentify": {
  "status_polling": false
}
```

需要独立健康信号时可手动开成 `true`，此时只对本机 `127.0.0.1` 做只读 GET `/status`。

## Windows 监听方式

Windows 优先使用系统 `ReadDirectoryChangesW`。日志没变化时，不做目录轮询。

非 Windows 或原生 watcher 不可用时才回退到低频 polling。

## Token 口径

- **Astra — EXACT**：Codex 本地 telemetry。
- **AGY — REPORTED**：AGY 日志/工具输出明确提供 usage 时统计。
- **Sol — ESTIMATED VISIBLE**：可见 prompt + packed context + response 的估算，不含隐藏 reasoning。
- Cached 是 Input 的子集，所以“处理 Token”使用 `Input + Output`，不会把 Cached 再加一次。

## 隐私

默认不保存完整 prompt、完整回复或大段工具输出，只保存计数、短预览和调用元数据。

```json
"privacy": {
  "store_prompt_text": false,
  "store_response_text": false,
  "store_tool_output": false,
  "preview_chars": 180
}
```

## 数据库

仅本项目：

```text
data\observatory.db
```

需要清空时先运行 `STOP.bat`，再运行 `RESET_DATABASE.bat`。

## 诊断

```powershell
powershell -ExecutionPolicy Bypass -File .\DIAGNOSE.ps1
```

只检查路径、Python、Agentify state，不修改外部程序。
