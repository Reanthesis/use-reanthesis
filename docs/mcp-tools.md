# MCP tools

The hosted server at `https://reanthesis.com/mcp` speaks Streamable HTTP in
JSON response mode: each JSON-RPC request is answered with a single JSON
body (`GET /mcp` returns `405` — there is no SSE stream). Authentication is
the OAuth connector token described in [auth.md](auth.md). Tool names and
argument names are a public interface; all operations are scoped to the
authorized account.

Tool errors set `isError` and carry one JSON object:

```json
{"code": "invalid_request", "message": "Provide exactly one selector: card_ids, deck_ids, or tags."}
```

`connector_revoked` or an HTTP `401` means the user must reconnect at
reanthesis.com.

## Connection and dashboard

### `whoami()`

Returns the connected account email and health. Call it first in a new
session; an authentication error here means reconnect, not retry.

### `study_status()`

The study dashboard: due and new counts, forecast, card states, retention,
and streaks. Use it to report study state after a batch.

## Navigation

### `list_decks()`

The account's decks with ids, names, and study counts.

### `create_deck(name)`

Creates a deck (name trimmed, 1–200 characters) and returns it.

### `list_cards(deck_id, limit?, cursor?)`

A deck's notes and their generated cards, paginated (`limit` up to 200; pass
the returned offset back as `cursor`). Note ids are for editing; card ids are
for `wake_cards` / `rest_cards`.

## Authoring

### `create_card(deck_id, front, back?, tags?)`

One basic note: `front` is a retrieval question, `back` the answer. New cards
are born active and enter the study queue immediately.

### `create_cloze(deck_id, text, extra?, tags?)`

A cloze note. `text` must contain `{{c1::answer}}` markers; each distinct
index becomes its own card. `extra` is optional evidence shown after grading.

### `update_card(note_id, fields, tags?)`

Replaces the note's **entire fields object** — a full replacement, not a
merge. Resend every field to keep (`front`/`back`, or `text`/`extra`).
Omitting `tags` keeps them; `[]` clears them.

### `delete_card(note_id)`

Permanently deletes the note and all its cards.

### `upload_image(data_base64, media_type?)`

Uploads a base64 raster image (PNG, JPEG, GIF, or WebP, 10 MB max) and
returns `{sha, markup}`; embed `markup` in a card field. Only for images that
are themselves the study content, like labeled diagrams.

## Activation

Cards are **active** (in the study queue) or **dormant** (paused: nothing
due, FSRS progress kept).

### `wake_cards(card_ids? | deck_ids? | tags?)`

Returns dormant cards to the study queue. Exactly one selector per call:
`card_ids` (≤1000), `deck_ids` (≤100), or `tags` (≤200). Returns how many
cards changed.

### `rest_cards(card_ids? | deck_ids? | tags?)`

Makes cards dormant. Same selectors and result shape as `wake_cards`.

### `find_tags(q, deck_id?, include_active?)`

Searches tags. By default it searches **dormant cards only** and returns each
tag with its dormant count — the set that can be woken. With
`include_active: true` it searches the whole collection, which is the right
mode when authoring: reuse the existing vocabulary instead of inventing
near-duplicate tags.
