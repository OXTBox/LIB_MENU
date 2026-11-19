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

- **Step 0** (18 Nov, a helper session, branch `menu-folders`, waiting for you): menus live per
  game or app now. Shipped: `Data/Default/<game or app>/Menus/` (menu files) and `Menus/Functions/`
  (the callbacks). Yours: the same in your Data folder, `Menus/<game or app>/` and its `Functions/`;
  your file wins, file by file. `Menu.Load "DeadDays"` loads one game's menus; `Menu.Load` alone
  still means the Library. Callback files are started as libraries when the menus load.
  `Library.txt` moved to `Data/Default/Library/Menus/`, with its first callback file beside it.
  This needs LIB_DATA's `data-menus` branch for your own files (without it, only the shipped menus).
- Tests: t43 now 88 checks, all pass on both engines. t50 13 checks pass. t39 87 of 89: the 2 that
  fail (On Git or Not's grey chip and ignored popup) failed the same way before this change.

## For the owner

- Try a board (Project Map or On Git or Not): click a box, pick "Explore here..." and
  "Leave comment...". They should work exactly as before.
- The boards work with or without this library: without it their menus are plain (no ending) and
  the help bar says
  "Menus need LIB_MENU".
- ~~Look at `Menus/Default/Library.txt`: is this how you want a menu file to read?~~ Answered 18 Nov
  (Project Map): menus live per game or app, `Data/Default/<game or app>/Menus/` holds the menu item
  lists and `Data/Default/<game or app>/Menus/Functions/` the callbacks the menus use (as in his 2009
  iGame3D). Step 0 below.
- Merged to main 18 Nov (owner: "MERGE!").

## Next steps (suggested; sized in the Priority Tube, the owner sets the order)

0. ~~Move to the owner's layout: `Data/Default/<game or app>/Menus/` (item lists) +
   `Menus/Functions/` (callbacks); `Menu.Load` takes the game or app name; user override the same
   shape in the Data folder; Library.txt moves under a `Library` app folder.~~ Done 18 Nov, branch `menu-folders`.

1. ~~A Library menu in a real stack~~ Done 18 Nov (branch `editor-library-menu`, here and in
   LIB_EDITOR, waiting for you): the iGame3D XT editor (the owner's pick). Its Library menu comes from
   `Data/Default/Ig3dEditor/Menus/Library.txt`: the old items (Models, Levels, Text, ... Set Data
   Folder...) plus **Data** and **Games**, filled from the Data folder each time the menu opens.
   A pick on a folder shows what is in it in the editor's own Library list (folders first, double-click
   to go in, ".." back), not Explorer; only "Explore here..." opens Explorer, at that folder. This
   also answers the "Later" note below for the editor. New: a `folders:` line with no kind = the
   folders at the top of the Data folder. Without LIB_MENU the editor's menu is the old one.
   Test t51 (30 checks, both engines); t43 88, t20 7, t37 30 still pass.
2. The Priority Tube and the Status Browser use `Menu.WithEnd` (rule 1).
3. ~~A `Menus` kind in LIB_DATA~~ Done 18 Nov (LIB_DATA branch `data-menus`): `Menus/<game or app>/` + `Functions/`, `Data.MenuFolder(app [, true])`; step 0 points `Menu.Load` at it.
4. Game pause menus follow rule 1 in developer mode only (still the owner's call)... We will do a "Game Popup Menu" review at a later date to see which game can get what. LIB_GAD main UI will have something for certain. 

## Later (owner, 18 Nov late evening, after testing the boards)
"Explore here..." works, but it opens a folder with 50+ scripts in it: "that open script in explorer
menu is going to blow people's minds, 50+ scripts in one folder, ...works and NOTE: We will return to
that later." Not now. When we return: show only what belongs to the thing clicked (its own files
first, or a short list to pick from) instead of the whole folder.
