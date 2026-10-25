# Model Context Protocol (MCP) & Optional AI Integration

Astuto Evolution includes a built-in **Model Context Protocol (MCP)** server over Streamable HTTP (`/mcp`) and an optional, opt-in **AI Provider** abstraction (`Ai::Client`).

---

## 1. MCP Server (`/mcp`)

The MCP endpoint is built on the official [MCP Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk) (`mcp` gem), speaks **Streamable HTTP** in stateless JSON mode (all protocol versions the SDK supports, currently up to `2025-11-25`; batched requests are not supported, as in the current spec), rejects cross-origin browser requests and authenticates with standard Astuto API keys (`Site Settings › API`). Only active moderators, admins, and owners can generate and use API keys.

- **Endpoint:** `POST https://<your-astuto-domain>/mcp`
- **Authentication:** `Authorization: Bearer <API_KEY>` (or `X-Api-Key: <API_KEY>`)

### Available MCP Tools

| Tool | Read-Only | Description |
|---|---|---|
| `list_boards` | Yes | Lists all feedback boards in the tenant along with approved post counts. |
| `search_posts` | Yes | Full-text and substring search across post titles and descriptions, with optional `board_id`, `post_status_id`, `approval_status`, and `limit`. |
| `top_requests` | Yes | Lists top customer requests ordered by `most_voted`, `trending`, `newest`, or `oldest`. |
| `get_post` | Yes | Retrieves a single post (by numeric ID or URL slug) including vote count, status, board, and all comments. |
| `get_roadmap` | Yes | Returns all roadmap columns (`show_in_roadmap = true`) and their assigned posts ordered by votes. |
| `create_post` | No | Creates a new approved feedback post in a board on behalf of the authenticated moderator/admin. |
| `update_post_status` | No | Updates a post's workflow status (`post_status_id`), board (`board_id`), or moderation status (`approval_status`) and notifies followers. |
| `add_comment` | No | Adds a comment, threaded reply (`parent_id`), or official post update (`is_post_update: true`) and triggers follower notifications. |

### Configuration Examples

#### Claude Code (CLI)

```bash
claude mcp add --transport http astuto https://feedback.example.com/mcp \
  --header "Authorization: Bearer tkn_admin_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

#### Cursor (`.cursor/mcp.json`)

```json
{
  "mcpServers": {
    "astuto": {
      "url": "https://feedback.example.com/mcp",
      "headers": {
        "Authorization": "Bearer tkn_admin_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

#### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "astuto": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://feedback.example.com/mcp",
        "--header",
        "Authorization: Bearer tkn_admin_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      ]
    }
  }
}
```

---

## 2. Optional AI Provider (`Ai::Client`)

AI features in Astuto Evolution are **100% opt-in**. When `AI_PROVIDER` or `AI_MODEL` is not set, no external AI requests are ever made and all core feedback features operate normally.

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `AI_PROVIDER` | `openai` (any OpenAI-compatible API), `ollama` (local), or `anthropic` | *(disabled)* |
| `AI_API_KEY` | API key for `openai` or `anthropic` (not required for `ollama`) | — |
| `AI_BASE_URL` | Custom API base URL (e.g., `http://ollama:11434/v1`, LiteLLM, vLLM) | Provider default |
| `AI_MODEL` | Model identifier, **required** (e.g. a current small model of your provider, or the name of a pulled Ollama model). There is no built-in default because model names change too often. | — |

### What is available

| Feature | Where | Status |
|---|---|---|
| Discussion summary | Post page in the v2 frontend (`/next`), moderator panel, button "Summarize discussion"; API `POST /api/app/v1/posts/:id/summary` | available (moderators only). Results are cached per post content for one day. |
| Board and tag suggestions | — | planned; needs tags (#171) |
| Changelog drafts | — | planned; needs the changelog feature |
| Translation of feedback | — | planned |

`Ai::Client` already contains the helpers for the planned features; they are not wired to the UI yet.

### Privacy & Data Protection Notice (Datenschutzhinweis)

- **Opt-in only:** Without `AI_PROVIDER` and `AI_MODEL` configured, zero data leaves your Astuto instance.
- **Data minimization:** Data is only sent when a moderator explicitly asks for it (today: the discussion summary). Then **only** the following fields are transmitted to the configured `AI_BASE_URL`:
  - Post title (`post_title`) and description (`post_description`)
  - Comment text bodies (`comment_bodies`) for thread summarization
  - Board names and descriptions (`board_names`) for board/tag classification
- **Never transmitted:** User email addresses, IP addresses, password hashes, session tokens, OAuth credentials, and webhook URLs are **never** sent to the AI provider.
- **Full data sovereignty:** For strict GDPR / on-premises compliance, set `AI_PROVIDER=ollama` and `AI_BASE_URL=http://ollama:11434/v1` so all inference runs on your own hardware.
