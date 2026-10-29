# REST API

`/api/v1` lets your own tools read and write feedback: boards, posts, comments, votes, statuses
and users. For AI assistants there is the MCP server ([mcp-and-ai.md](mcp-and-ai.md)).

## Authentication

Moderators and admins create an **API key** in their profile (Profile › API key). It is shown
once; a new key replaces the old one. Send it with every request:

```bash
curl -H "Authorization: Bearer $ASTUTO_API_KEY" https://feedback.example.com/api/v1/posts
```

The key acts as its owner: changes appear in the audit log with source *REST API*, and the key
stops working when the account loses its moderator role or is blocked.

## Reference

The OpenAPI description is served at `/api-docs/v1/swagger.yaml` (with multi-tenancy on the
`api.` subdomain of `BASE_URL`) and kept in the repository at `swagger/v1/swagger.yaml`. Load it
into Swagger UI, Postman, Insomnia or a client generator.

| Resource | Endpoints |
| --- | --- |
| Boards | list, show, create |
| Statuses | list |
| Posts | list, show, create (also for another author), update, delete; move to another board, change status, approve, reject |
| Comments | list, show, create, update, delete; mark or unmark as post update |
| Votes | list, show, vote and unvote on behalf of a user |
| Users | list, show, find by email, create, block |

## Limits and conventions

- 100 requests per 5 minutes per IP address and per key; more get HTTP 429.
- JSON in and out; times in ISO 8601 (UTC).
- Responses include email addresses of users, since only moderators and admins hold keys.
- Posts can carry a source (`source_url`, `source_label`), e.g. the Slack thread they came from.
