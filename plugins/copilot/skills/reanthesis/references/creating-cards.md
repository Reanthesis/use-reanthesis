# Creating cards

## Decks

Find the best existing deck with `list_decks`. If none fits, propose a focused
name (`create_deck`, e.g. "MCAT Biochem") and create it after the user agrees.
One deck per subject or exam, not per lecture.

## Card craft

Each card retrieves one fact, relationship, procedure step, or decision.

- **Atomic.** Split a long explanation into several cards rather than hiding
  multiple facts behind one broad prompt.
- **Retrieval cue.** The front makes the learner retrieve: "What is the
  mechanism of ...?", "Which finding distinguishes ... from ...?" — never a
  topic label like "Renal physiology", never yes/no.
- **Self-contained.** Include the minimum context needed to answer without the
  lecture in hand. Keep the student's own wording when it is already precise.
- **Concise back.** Sufficient to confirm the answer; not a second copy of the
  notes.

Use `create_card(deck_id, front, back?, tags?)` for question-and-answer pairs.
New cards are born active and enter the study queue immediately.

## Cloze cards

Use `create_cloze(deck_id, text, extra?, tags?)` for definitions, named
relationships, and enumerations that retrieve better in context. `text` must
contain `{{c1::answer}}` markers; each distinct index becomes its own card.

Split enumerations across indexes so each item is retrieved separately:

```
The three germ layers are {{c1::ectoderm}}, {{c2::mesoderm}}, and {{c3::endoderm}}.
```

Add a short `extra` only when it supplies evidence or a distinguishing detail.
If the material tests better as separate questions, use basic cards instead.

## Tags

Reuse the deck's existing vocabulary — check `find_tags` with
`include_active: true` before inventing tags. Otherwise use lowercase
kebab-case with small namespaces: `subject:anatomy`, `topic:renal-physiology`,
`source:lecture-04`. Apply the same subject and topic tags across a batch; no
near-duplicates like `renal` vs `renal-system`. Tags are how cards are found
and woken later — add only ones that will serve that.

## Images

Use `upload_image(data_base64, media_type?)` (PNG, JPEG, GIF, or WebP, 10 MB
max) only when the image itself is the study content — a labeled diagram, a
pathway, a figure whose spatial arrangement must be recalled. Put the returned
`markup` in a card field. If the image is merely a source to read (handwritten
notes, a screenshot of prose), read it and write text cards instead.

## Editing

- `update_card(note_id, fields, tags?)` REPLACES the entire fields object —
  fetch the note first (`list_cards`) and resend every field you keep. Omit
  `tags` to leave tags unchanged; `[]` clears them.
- `delete_card(note_id)` permanently removes the note and all its cards.
  Confirm with the user before deleting anything with review history.

## Batches

Create cards with repeated tool calls, then report what was created and
surface any individual failure. Confirm the outcome with `study_status` when
the user wants to know what is now due.
