# Waking dormant cards

The loop that keeps a growing collection studyable. A Reanthesis card is either
**active** — in the study queue, reviews come due — or **dormant** — paused,
nothing due, all FSRS progress kept. New cards are born active. Nothing is
lost by resting; nothing needs re-learning from zero after waking.

## When to wake, when to rest

- **Wake** when the user signals real exposure to a topic again: a new rotation
  or block, an exam announced, "I'm back on renal this week."
- **Rest** when material is finished for now: the exam passed, the rotation
  over, a deck imported for later. Resting beats deleting — the scheduling
  history stays.

## Find before you change

`find_tags(q, deck_id?, include_active?)` is the entry point, and its switch
decides what you are doing:

- **Default (`include_active` false): the waking path.** Searches dormant
  cards only and returns each tag with its dormant count — exactly the set
  that *can* be woken. If the user mentions a topic, search it here first.
- **`include_active: true`: the authoring path.** Searches the full
  collection, showing the whole tag vocabulary. Use it before creating cards,
  to reuse existing tags and to notice the material already exists.

The rule that follows: when a topic comes up, check the dormant side before
drafting anything new. Wake what exists; create only what is missing.

## Selecting cards

`wake_cards` and `rest_cards` take **exactly one** selector per call:

- `tags: ["topic:renal-physiology"]` — the usual choice; this is what good
  tagging bought you.
- `deck_ids: [...]` — whole decks, for coarse moves like shelving a finished
  course.
- `card_ids: [...]` — surgical, from `list_cards` output.

Use the narrowest selector that matches the user's intent, and say what
changed: both tools return how many cards moved. `study_status` shows the
resulting due counts when the user wants the after-picture.

## Example

> "I start cardio next week, can you set me up?"

1. `find_tags(q="cardio")` → `topic:cardiology` has 84 dormant cards.
2. `wake_cards(tags=["topic:cardiology"])` → 84 cards active.
3. Skim the user's new syllabus; draft cards only for subtopics with no
   coverage, tagged into the same vocabulary.
4. "84 cards are back in your queue and I added 12 new ones — open Reanthesis
   and hit Study."
