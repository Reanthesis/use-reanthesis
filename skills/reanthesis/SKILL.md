---
name: reanthesis
description: Create and manage Reanthesis flashcards when the user shares lecture notes, PDFs, or study images, asks for flashcards, or mentions Reanthesis. Covers drafting basic and cloze cards, tagging, and waking or resting dormant cards by tag, deck, or card.
license: Apache-2.0
---

# Reanthesis

Reanthesis is a spaced-repetition study app scheduled by FSRS. You tend the
cards; the user studies them in the app. Tools come from the hosted MCP server
at `https://reanthesis.com/mcp`.

## Every session

1. Call `whoami` first. On an auth error, have the user add
   `https://reanthesis.com/mcp` as a connector in their client's settings and
   tap **Allow** at reanthesis.com — then stop. Never pretend cards were saved.
2. Read all supplied material before drafting anything.
3. Check what already exists: `list_decks`, and `find_tags` with
   `include_active: true`. Waking dormant cards beats creating duplicates.
4. Propose the batch — deck, topics, sample fronts and backs — and get the
   user's nod before creating, unless they asked for immediate import.
5. Finish with: open Reanthesis and hit **Study**.

## References

- Drafting decks and cards — fronts and backs, cloze deletions, tags, images,
  edits: [references/creating-cards.md](references/creating-cards.md)
- Reading the collection and waking or resting dormant cards, the loop that
  keeps a growing collection studyable:
  [references/waking-dormant-cards.md](references/waking-dormant-cards.md)

## Hard rules

- `update_card` REPLACES the note's entire fields object. Resend every field
  you want to keep.
- `wake_cards` and `rest_cards` take exactly one selector: `card_ids`,
  `deck_ids`, or `tags`.
- `find_tags` searches dormant cards by default; pass `include_active: true`
  when authoring so you see the full tag vocabulary.
- Tool errors return `{code, message}`. Report them plainly;
  `connector_revoked` means the user must reconnect at reanthesis.com.
