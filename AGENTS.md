# CLAUDE.md

本文件为在该仓库中使用 Claude Code (claude.ai/code) 时提供指导。

## 项目概览

`claude-switch` 是一个 D 语言 CLI 工具，用于管理不同 Claude API 配置文件之间的切换。它允许用户维护多个 API 路由器配置（存储在 `~/.config/ai-switch.json` 中），并通过更新 Claude Code 的设置文件（`~/.claude/settings.json`）在它们之间快速切换。

该项目还包括 `setup-claude-code.sh`，这是一个用于配置 Claude Code 以使用带身份验证的自定义 API 路由器的综合设置脚本。

## 架构

### 单文件应用

主应用逻辑包含在 `source/app.d` 中。结构很简洁：

- **配置管理**：读取和解析 JSON 配置文件
- **配置文件系统**：支持多个命名配置文件（例如："ikun"、"yes"）
- **设置更新**：使用选定配置文件的凭证修改 Claude Code 的设置文件
- **默认配置**：如果缺少默认配置，则自动创建

### 关键数据流

1. 用户运行：`./claude-switch <profile>`
2. 应用读取：`~/.config/ai-switch.json` 包含所有配置文件
3. 应用定位：指定的配置文件并提取 `baseUrl` 和 `authToken`
4. 应用更新：`~/.claude/settings.json` 使用选定配置文件的凭证
5. 应用显示：更新的设置以确认切换

### 配置文件

- **输入**：`~/.config/ai-switch.json` - 用户的配置文件配置
- **输出**：`~/.claude/settings.json` - Claude Code 设置（在 `env` 对象中）

每个配置文件包含：
- `baseUrl`：API 端点 URL
- `authToken`：API 的身份验证令牌

### 环境变量包装器

代码包含一个自定义 `environment` 结构体，该结构体包装 C 绑定到 `getenv()`，用于安全的环境变量访问和适当的错误处理。

## 常见开发任务

### 构建应用

```bash
dub build
```

这会在 `./claude-switch` 处创建可执行文件。目录列表中显示的二进制文件（`claude-switch`）是编译后的输出。

### 运行应用

```bash
dub run -- <profile>
```

或直接使用二进制文件：
```bash
./claude-switch <profile>
```

可用的配置文件：`ikun`、`yes`

### 运行测试

```bash
dub test
```

### 代码检查

```bash
dub lint
```

## 模块依赖

应用仅使用 D 标准库模块：
- `std.stdio`：I/O 操作
- `std.file`：文件操作（读/写、存在性检查）
- `std.path`：路径操作（buildPath、dirName）
- `std.json`：JSON 解析和序列化
- `std.algorithm`：算法实用程序
- `std.string`：字符串操作
- `std.conv`：类型转换

## 设置脚本

`setup-claude-code.sh` 是一个配套脚本，用于配置 Claude Code 以使用自定义 API 路由器。主要特性：

- 交互式和非交互式模式
- API 连接测试与余额/消费验证
- 自动 shell 配置文件检测（bash、zsh、fish）
- 修改前的设置备份
- 环境变量配置（`ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`）

使用 `./setup-claude-code.sh --help` 查看可用选项。

## 重要实现说明

1. **JSON 操作**：使用 `parseJSON()` 进行解析，使用 `toPrettyString()` 进行序列化
2. **错误处理**：当找不到配置文件或无法读取文件时抛出带有描述性消息的异常
3. **目录创建**：使用 `mkdirRecurse()` 确保在写入文件之前父目录存在
4. **文件 I/O**：使用 `to!string()` 将文件内容转换为字符串以进行 JSON 解析
5. **默认配置**：使用占位符凭证自动生成；用户必须更新为实际值
