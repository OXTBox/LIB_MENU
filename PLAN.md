# LIB_MENU: rules for menus everywhere (a plan)

Monday, November 17, 2026. One page by Claude (Opus 5.5) from two board comments of the owner:
"'Leave comment' and 'Explore here...' should be options in the menus. Maybe that should be LIB_MENU?
ie, rules and records and procedural scripts for menus that are consistent throughout our input
system" (On Git or Not) and "the interface must be forever gateway to the file system, because it
blocks the file system. and the file system doesn't show relationships like this needs to show"
(Project Map). The owner corrects it and decides whether LIB_MENU becomes its own LIB (no repo made).

## 1. Why

The boards (Project Map, On Git or Not, Priority Tube) cover the screen, so they hide Explorer; and
Explorer shows folders, not what feeds what, what waits on whom, what is loose. So the boards must be
the way **in**: every thing on them reachable, commentable and openable from where it is drawn.
A menu that behaves the same everywhere is how that stays easy.

## 2. The rules

1. **Every menu ends the same way**, after a separator line:
   `Leave comment...` (a comment on that thing, the same big box as a right-click) and
   `Explore here...` (Explorer at that thing's folder, its file selected when it is one file).
   One handler builds the ending; no menu writes these lines itself.
2. **Right-click = comment, on anything**: a box, a chip, a string, a note, a panel line, the black.
3. **Left-click on a thing = its menu** (a part, a chip, a note, a red blocker). The first line,
   greyed, says what was clicked; the thing's own lines come next; the ending last.
4. **Nothing touches the disk until a line is picked.** Paths travel with the board's data
   (`map_data.txt`), so opening a menu never waits on the WSL bridge. Explorer is started with
   `start` and never waited for.
5. **A pick writes a record, it does not do the work.** Decisions (Reviewed, Feedback, Commit /
   Ignore / Delete / Leave) are one appended line each in `LIB_LLMIN/LIB_DEV/<NAME>.txt`; the last
   line for a thing wins; Claude carries them out and the next rebuild shows the result. A board never
   runs git and never deletes.
6. **What is decided shows** on the board (the chip says "2 of 3 decided", the menu line says
   "= COMMIT"), so the owner never has to remember what he clicked.
7. **Labels are safe**: menu text treats `( ! - / & |` as commands, so names pass through one
   cleaning function first (`pmMenuSafe`).
8. **Same words everywhere**: "Leave comment...", "Explore here...", "Open in Explorer",
   "Reviewed", "Feedback...", "Commit", "Ignore", "Delete", "Leave". A new action gets a word here first.

## 3. Where the records go

| Record | File (LIB_LLMIN/LIB_DEV/) | Line |
|---|---|---|
| comments | BOARD_COMMENTS.txt | id, date, board, target, words, open/deleted/done, where, text |
| reviews | REVIEW_STATE.txt, REVIEW_FEEDBACK.txt | the Status Browser's own formats |
| blocker notes | MAP_NOTES.txt | date, part, blocker, feedback/file, text |
| git decisions | GIT_DECISIONS.txt | date, folder, Windows path, commit/ignore/delete/leave |
| wake Claude | TELL_CLAUDE.txt | date, tell, from which board |

`for_review.py feedback` prints them at every session start.

## 4. Where the code is now, and where LIB_MENU would take it

Today the rules live in the shared board script, `LIB_DEV/livecode/board_canvas.livecodescript`:
`pmMenuEnd` (the ending), `pmPopupMenu` / `pmMenuSet` (every popup goes through these),
`pmMenuEndPick`, `pmExploreHere`, `pmDecide`. The Priority Tube and other stacks do not use it yet.

If the owner says go, **LIB_MENU** would be a small library (`menu` prefix): the ending, the safe
labels, "append a record line", "Explore here" and the record formats above, used by every stack
with menus (boards, Priority Tube, Status Browser, the games' pause menus), with one headless test.
**Owner, 17 Nov:** its own LIB. "I like crafty reusable, user hackable procedural menu tricks."
Still open: should game pause menus follow rule 1 too? [suggested: yes, in developer mode only].
