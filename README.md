# 🏠 OpenChamber Deployment

> Self-hosted [OpenCode](https://opencode.ai) + [OpenChamber](https://openchamber.dev) stack with [OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent) integration.

## 📖 Overview

This Docker Compose setup runs a fully self-hosted AI coding environment:

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| 🔌 **OpenCode** | `ghcr.io/anomalyco/opencode` | `4096` (internal) | Headless AI coding agent API |
| 🖥️ **OpenChamber** | Built locally from source | `3000` (exposed) | Web GUI for OpenCode |

## 🚀 Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/BRAVO68WEB/openchamber-deployment.git
cd openchamber-deployment
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```env
# 🔑 AI Provider API Keys
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...

# 🔒 OpenCode Server Auth
OPENCODE_SERVER_PASSWORD=your-strong-password
OPENCODE_SERVER_USERNAME=opencode

# 🔐 OpenChamber Web UI
OPENCHAMBER_UI_PASSWORD=your-strong-password
OPENCHAMBER_PORT=3000
```

### 3. Launch the stack

```bash
docker compose up -d --build
```

### 4. Access OpenChamber

Open [http://localhost:3000](http://localhost:3000) in your browser and log in with your `OPENCHAMBER_UI_PASSWORD`.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                Docker Network                   │
│                                                 │
│  ┌───────────────────┐  ┌─────────────────────┐ │
│  │   opencode        │  │   openchamber       │ │
│  │   (headless API)  │◄─│   (web GUI)         │ │
│  │   :4096           │  │   :3000             │ │
│  └───────────────────┘  └─────────────────────┘ │
│          │                        │             │
│  ┌───────┴────────────────────────┴───────────┐ │
│  │          Named Volumes                     │ │
│  │  • user-workspaces   (code & projects)     │ │
│  │  • opencode-config   (opencode.json)       │ │
│  │  • opencode-data     (sessions, auth)      │ │
│  │  • opencode-cache    (plugin cache)        │ │
│  │  • openchamber-config (UI settings)        │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## 📦 What's Inside

### OpenCode Container
- 🤖 [OpenCode](https://opencode.ai/docs) — AI coding agent (headless server mode)
- 🔑 HTTP basic auth via `OPENCODE_SERVER_PASSWORD`
- 📡 API available at `http://opencode:4096`

### OpenChamber Container
- 🌐 [OpenChamber](https://openchamber.dev/docs) — Web-based GUI for OpenCode
- 🔧 [nvm](https://github.com/nvm-sh/nvm) + Node.js 22
- 📦 [opencode-ai](https://www.npmjs.com/package/opencode-ai) — npm package
- 📦 [@openchamber/web](https://www.npmjs.com/package/@openchamber/web) — npm package
- 🧩 [OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent) — Plugin (installed on first boot)
- 🔐 Passwordless `sudo` for the `openchamber` user
- 🔑 SSH key auto-generation

## 🔐 Security

| Layer | Protection |
|-------|-----------|
| OpenCode API | HTTP Basic Auth (`OPENCODE_SERVER_PASSWORD`) |
| OpenChamber UI | UI Password (`OPENCHAMBER_UI_PASSWORD`) |
| Docker Network | Internal bridge network (port 4096 not exposed) |
| Container User | Non-root `openchamber` user (UID 1000) with sudo |

## 🧩 OhMyOpenCode

[OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent) is installed automatically on first boot. It adds:

- 🤖 11 specialized AI agents (orchestrator, deep worker, oracle, etc.)
- 🔀 Team Mode — parallel multi-agent collaboration
- ⚡ `ultrawork` command — single-word trigger for complex tasks
- 🔧 54+ lifecycle hooks
- 🛠️ Built-in MCP servers (web search, docs, code search)
- 📝 Hash-anchored edit tool for reliable file edits

## 💾 Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `openchamber-user-workspaces` | `/workspaces` (opencode) | User code & projects |
| | `/home/openchamber/workspaces` (openchamber) | |
| `openchamber-opencode-config` | `/root/.config/opencode` | OpenCode config |
| `openchamber-opencode-data` | `/root/.local/share/opencode` | Sessions, auth data |
| `openchamber-opencode-cache` | `/root/.cache/opencode` | Plugin npm cache |
| `openchamber-openchamber-config` | `/home/openchamber/.config/openchamber` | UI settings |

### 📂 Using a bind mount for user code

To use a local directory instead of a named volume, update `docker-compose.yml`:

```yaml
volumes:
  - /path/to/your/code:/workspaces
```

## 🛠️ Common Commands

```bash
# ▶️ Start the stack
docker compose up -d

# ⏹️ Stop the stack
docker compose down

# 🔄 Rebuild after changes
docker compose up -d --build

# 📋 View logs
docker logs -f opencode
docker logs -f openchamber

# 🐚 Shell into openchamber container
docker exec -it openchamber bash

# 🔍 Check container health
docker ps --filter name=opencode --filter name=openchamber

# 🧹 Full cleanup (removes volumes too!)
docker compose down -v
```

## ⚙️ Configuration

### OpenCode

Mount your own `opencode.json` by editing `config/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-openagent"]
}
```

📖 [OpenCode Configuration Docs](https://opencode.ai/docs/config)

### OpenChamber

OpenChamber settings are stored in the `openchamber-openchamber-config` volume. Access via:

```bash
docker exec -it openchamber ls ~/.config/openchamber/
```

📖 [OpenChamber Docs](https://openchamber.dev/docs)

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | — | Anthropic API key |
| `OPENAI_API_KEY` | — | OpenAI API key |
| `GOOGLE_API_KEY` | — | Google Gemini API key |
| `GEMINI_API_KEY` | — | Alternative Gemini key |
| `OPENCODE_SERVER_PASSWORD` | — | **Required.** HTTP basic auth password |
| `OPENCODE_SERVER_USERNAME` | `opencode` | HTTP basic auth username |
| `OPENCHAMBER_UI_PASSWORD` | — | **Required.** Web UI password |
| `OPENCHAMBER_PORT` | `3000` | Host port for OpenChamber |

## 🔧 Troubleshooting

### OpenChamber can't connect to OpenCode

```bash
# Check opencode is healthy
docker ps --filter name=opencode

# Test connection from openchamber
docker exec openchamber curl -u opencode:YOUR_PASSWORD http://opencode:4096/
```

### Permission denied on volumes

```bash
# Fix ownership (UID 1000 = openchamber user)
docker exec openchamber sudo chown -R openchamber:openchamber ~/.config/openchamber
```

### OhMyOpenCode not installed

```bash
# Manually trigger install
docker exec openchamber bash -c "source ~/.nvm/nvm.sh && bunx oh-my-openagent install"
```

## 📚 References

- 📖 [OpenCode Documentation](https://opencode.ai/docs)
- 📖 [OpenCode GitHub](https://github.com/anomalyco/opencode)
- 📖 [OpenChamber Documentation](https://openchamber.dev/docs)
- 📖 [OpenChamber GitHub](https://github.com/openchamber/openchamber)
- 📖 [OhMyOpenCode GitHub](https://github.com/code-yeongyu/oh-my-openagent)
- 📖 [OpenCode Docker Guide](https://opencode.ai/docs#using-docker)
- 📖 [nvm Documentation](https://github.com/nvm-sh/nvm)

## 📄 License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ using <a href="https://opencode.ai">OpenCode</a> + <a href="https://openchamber.dev">OpenChamber</a> by <a href="https://github.com/BRAVO68WEB">@BRAVO68WEB</a>
</p>
