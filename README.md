# LIB_MENU

Menus for every stack, one way: crafty, reusable, user-hackable procedural menu tricks
(the owner's words, 17 Nov 2026).

- Every menu ends the same: "Leave comment..." and "Explore here...".
- Right-click anything = comment on it.
- The menus are the way into the file system: they show what Explorer cannot (how things relate).
- A menu choice that matters writes one record line (comments, reviews, git decisions...).

Read `PLAN.md` for the rules and the record formats. Today the code lives in the boards' script
(`LIB_DEV/livecode/board_canvas.livecodescript`: `pmMenuEnd`, `pmPopupMenu`, `pmMenuSet`,
`pmExploreHere`, `pmDecide`); the next step moves it here as `livecode/lib_menu.livecodescript`
(prefix `Menu.`) with one headless test, and the boards, the Priority Tube and the Status Browser use it.

Not yet: menus built from a text file a user can edit (the hackable part), so anyone can add a line
to a menu without touching a script.
