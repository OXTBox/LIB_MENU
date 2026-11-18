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

## 5. The owner's 2009 way: the model for step 2

The owner, 17 Nov: "this is how I used to do it" — iGame3D's
`Data/Scripts/Functions/Menus/` (11 Lua files, 2009-2022), "I really like my whole DATA path system".
What it does, and what LIB_MENU keeps from it:

| iGame3D 2009 | What it means | LIB_MENU |
|---|---|---|
| one file per menu (`file_menu_functions.lua`, `entities_menu_functions.lua`, ...) | add a file, get a menu | one menu = one small file in a Menus folder |
| the items are a plain list (`entityMenuText={"camera","colors",...}`), grouped by path `"File/Save/Level"` | the menu's words are data, not code | menu lines are `Head/Sub/Item` paths, one a line |
| one `fill_<Menu>` builds it, one `<menu>MenuPick(path)` answers it; `main_menu_callback` routes by the first word of the path | one router, one answer per menu | `Menu.Fill` reads the file; a pick sends `menuPick` with the whole path to the stack that owns it |
| **the Library menu is the Data folder's own kinds** (BVH, Emitters, Fluid, FontPngs, GUI, Images, Levels, Scripts, Sounds, Text, Shaders, WIF, WTF), each opening a browser for that kind | **the folder tree is the menu**: make a folder in Data, the menu grows | a Library menu filled from the Data folder (LIB_DATA's `Data.Folder`), each kind opening its browser / "Explore here..." |
| menus live in `Data/Scripts/Functions/Menus`, beside everything else the game loads | a user hacks menus the same way as levels or scripts: by files in Data | the Menus folder lives in the Data folder (`Data.Path("Menus", ...)`), shipped defaults copied there once |

### 5b. The 2013 version: `Data/Scripts/Default/Menus` (the owner pointed here too)

The same menus two years on (12 files; `Functions/Menus` is the older 2009 copy). What it adds:

| iGame3D 2013 | What it means | LIB_MENU |
|---|---|---|
| **Default/** is the engine's shipped set; `default_Globals.lua` keeps a list of menu names (`gDefault_MenuFunctions`) and loads `Default/Menus/<name>_menu.lua` for each | the list of menus is data too; the folder name says "this is the factory set" | a `Default` Menus folder ships with LIB_MENU and is never edited; the user's own folder in Data wins over it, file by file |
| every loaded file is written into `gInit_Function_Paths` (path, name); "reset to default simply runs this whole file" | a registry of what was loaded from where; reset = load the defaults again | `Menu.Loaded()` lists each menu and the file it came from; `Menu.Reset` reloads the Default set |
| **the Wizard menu is `listFolders(Data/Wizards/)`**: each folder is an item, a pick opens that wizard (`OPEN_WIZARD_WINDOWS`) | not a list at all: **drop a folder in, the menu grows** | any menu line can be `folders: <Data kind>` and is filled from that Data folder at open time (Wizards, Games, Levels, ...) |
| Library picks all go through one `UniversalBrowse(pick)` (one browser for every kind; Console, WIF and WTF get their own) | one answer for many items, special cases only where needed | a menu file may name one handler for all its items; the item path is passed along |
| `main_menu` routes by the first word of the path, Wizard added with two lines | adding a whole menu is two lines in one router | the router needs no edit: the first word finds the menu file's handler |

So step 2 ("menus from a text file a user can edit") becomes: a Default menu set plus the user's own menu files in the Data folder (his win), menus filled from Data folders at open time (the Wizard trick),
the Library menu grown from the Data folder's kinds, and every menu still ending with
"Leave comment..." / "Explore here..." (rule 1).
