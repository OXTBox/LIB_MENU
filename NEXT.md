# LIB_MENU: what next

18 Nov 2026, by Claude (Opus 5.5, a helper session). On branch `menu-steps`, waiting for the owner.

## Done

- **Step 1**: the library, `livecode/lib_menu.livecodescript`. The ending ("Leave comment..." /
  "Explore here..."), safe labels, one record line, Explorer. The two boards now use it (LIB_DEV,
  branch `on-git-or-not`); the boards load it themselves.
- **Step 2**: menus from files. `Menus/Default/` ships here; your own files in the Data folder's
  `Scripts/Menus/` win file by file. Lines are `Head/Sub/Item`; `folders: <Data kind>` fills a menu
  from that folder when it opens; `kinds:` lists the Data kinds; one handler a menu; `Menu.Loaded()`
  and `Menu.Reset`. One example: `Menus/Default/Library.txt`.
- Tests: t43 (57 checks), t39 (89, now in its own work folder: it no longer touches your real
  comments or decisions).

## For the owner

- Try a board (Project Map or On Git or Not): click a box, pick "Explore here..." and
  "Leave comment...". They should work exactly as before.
- The boards work with or without this library: without it their menus are plain (no ending) and
  the help bar says
  "Menus need LIB_MENU".
- Look at `Menus/Default/Library.txt`: is this how you want a menu file to read?

## Next steps (suggested)

1. A Library menu in a real stack (the Status Browser or a game's developer pause menu), built
   with `Menu.Load` + `Menu.Show "Library"`.
2. The Priority Tube and the Status Browser use `Menu.WithEnd` (rule 1).
3. A `Menus` kind in LIB_DATA (today: `Scripts/Menus`, which needs no change there).
4. Game pause menus follow rule 1 in developer mode only (still the owner's call).
