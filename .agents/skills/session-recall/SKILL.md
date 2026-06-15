---
name: session-recall
description: Recover and summarize prior Codex conversations from local Codex history and session logs. Use when the user asks what happened in a previous chat, asks to "remember" past work, wants the last or previous session, gives a specific date or approximate time, wants to search old dialogs by keyword/topic/project, or asks to inspect Codex files/config for prior conversation context.
---

# Session Recall

Use local Codex logs instead of claimed model memory. Base the answer only on files found under `CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"`.

## Primary Files

- `$CODEX_HOME_DIR/history.jsonl`: fastest way to see recent user messages and map them to `session_id`
- `$CODEX_HOME_DIR/session_index.jsonl`: thread names and timestamps
- `$CODEX_HOME_DIR/sessions/YYYY/MM/DD/*.jsonl`: full session transcripts
- `$CODEX_HOME_DIR/archived_sessions/*.jsonl`: fallback for older moved sessions

Treat `config.toml`, `state_*.sqlite`, and `logs_*.sqlite` as fallback only. Conversation recall should usually come from `history.jsonl` and `sessions/.../*.jsonl`.

## Quick Workflow

1. Identify the selector the user gave: `last`, `previous`, specific date, date plus approximate time, keyword, project path, or session id.
2. Start from `history.jsonl` to find candidate `session_id` values and the user's own wording.
3. Open the matching `sessions/.../*.jsonl` file to reconstruct the conversation.
4. Answer with exact date and time when possible, name the session file used, and summarize only what the logs show.
5. If multiple sessions match, say that and present the nearest 2-3 candidates instead of guessing.

## Common Retrieval Patterns

### Last or Previous Session

Use:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
tail -n 40 "$CODEX_HOME_DIR/history.jsonl"
ls -1t "$CODEX_HOME_DIR"/sessions/*/*/*/*.jsonl 2>/dev/null | head -10
```

If the user asks for the previous session while already in a new chat, do not return the current session. Pick the most recent distinct earlier `session_id`.

### Specific Day

Use the exact calendar date, not relative wording:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ls -1 "$CODEX_HOME_DIR/sessions/YYYY/MM/DD"/*.jsonl 2>/dev/null
rg -n 'YYYY-MM-DD|keyword|session_id' "$CODEX_HOME_DIR/history.jsonl"
```

If the user says "yesterday" or "that day", convert it to an absolute date in the answer.

### Approximate Time on a Day

List that day's session files and choose the nearest timestamp:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ls -1 "$CODEX_HOME_DIR/sessions/YYYY/MM/DD"/*.jsonl
```

Then open the closest candidate and verify by reading nearby user messages.

### Keyword, Topic, or Project Search

Search both the lightweight index and the full transcripts:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
rg -n 'CAMvisualD|virtual camera|docker|build|mic' \
  "$CODEX_HOME_DIR/history.jsonl" \
  "$CODEX_HOME_DIR/sessions" \
  "$CODEX_HOME_DIR/archived_sessions"
```

Prefer the user's own exact phrase first, then broaden the search if needed.

### Session ID Search

When a `session_id` is already known, resolve it directly:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
find "$CODEX_HOME_DIR/sessions" "$CODEX_HOME_DIR/archived_sessions" \
  -type f -name '*session-id-fragment*.jsonl' 2>/dev/null
```

## Interpretation Rules

- Use `history.jsonl` for quick mapping, not as the sole source for a full recap.
- Use the session JSONL for the real summary, because it contains assistant actions, tool calls, and final messages.
- Prefer exact dates and times in the response.
- State clearly when an answer is inferred from nearby matches rather than directly proven.
- Do not invent missing context.
- If the logs are absent or incomplete, say what was found and why it is insufficient.

## Response Pattern

Keep the answer short and concrete:

1. State which session you found, with exact date and path.
2. Say what was discussed or changed.
3. Mention the main files or actions if they appear in the log.
4. Offer to open that session deeper or continue from that point.

## Useful Commands

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
tail -n 40 "$CODEX_HOME_DIR/history.jsonl"
tail -n 20 "$CODEX_HOME_DIR/session_index.jsonl"
ls -1t "$CODEX_HOME_DIR"/sessions/*/*/*/*.jsonl 2>/dev/null | head -10
rg -n 'keyword' "$CODEX_HOME_DIR/history.jsonl" "$CODEX_HOME_DIR/sessions" "$CODEX_HOME_DIR/archived_sessions"
sed -n '1,120p' /path/to/session.jsonl
tail -n 120 /path/to/session.jsonl
```
