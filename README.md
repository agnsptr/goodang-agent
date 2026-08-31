# Goodang Agent

Autonomous Customer Service Agent for Goodang — built with Google ADK + Temporal.

**Channel:** Telegram  
**Primary workflow:** CS Goodang — Guru Ingin Pesan

## Architecture

```
Telegram → FastAPI Webhook → ADK Agent → Structured Command → Temporal → Goodang Services → POS_TRANSACTION_LOG
```

## Core Principles

- **AI understands.** System validates.
- **Temporal executes.** Database records.
- Chat ≠ Order ≠ Transaction
- No guessing. No bypass. No direct DB mutation. No transaction without confirmation.

## Documentation

Specification documents are in [`docs/`](docs/):

| Doc | Description |
|-----|-------------|
| `1. GOODANG_ADK_AGENT_SPECIFICATION.md` | Main development specification |
| `2. GOODANG_AGENT_CONTRACT.md` | Agent contract |
| `3. GOODANG_TOOL_CONTRACT.md` | Tool contract |
| `4. GOODANG_DATA_CONTRACT.md` | Data contract |
| `5. GOODANG_TEMPORAL_WORKFLOW_SPEC.md` | Temporal workflow spec |
| `9. GOODANG_ADK_IMPLEMENTATION_SPEC.md` | ADK implementation spec |

## Development Phases

1. ADK Skeleton
2. Read-only Integration
3. Draft Order
4. Temporal
5. Confirmation Gate
6. Transaction
7. Telegram
8. Evaluation
9. Production

## References

- [Google ADK](https://adk.dev/)
- [Google Agents CLI](https://google.github.io/agents-cli/guide/development/)
- [Temporal](https://docs.temporal.io/)
