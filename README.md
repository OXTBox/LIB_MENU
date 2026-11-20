# LIB_MENU

Menus for every stack, one way: crafty, reusable, user-hackable procedural menu tricks
(the owner's words, 17 Nov 2026). Read `PLAN.md` for the rules and the record formats;
`NEXT.md` says where we are.

- Every menu ends the same: "Leave comment..." and "Explore here...".
- Right-click anything = comment on it.
- The menus are the way into the file system: they show what Explorer cannot (how things relate).
- A menu choice that matters writes one record line (comments, reviews, git decisions...).

## Use it

```
start using stack "<projects>/LIB_MENU/livecode/lib_menu.livecodescript"
set the text of button "Popup" to Menu.WithEnd("(About this" & return & "Open")
```

The stack that owns the menu answers the two ending lines itself:

```
on menuPick pItem
   if Menu.IsEnd(pItem) then Menu.EndPick pItem, "what was clicked", the long id of this stack
end menuPick
on menuLeaveComment pTarget   -- "Leave comment..."
on menuExploreHere pTarget    -- "Explore here..."
```

| Handler | Does |
|---|---|
| `Menu.End()` | the ending: a line, "Leave comment...", "Explore here..." |
| `Menu.WithEnd(menu)` | a menu's text with the ending after it |
| `Menu.IsEnd(item)`, `Menu.EndPick item, target, object` | is it an ending line; send it back to the owner |
| `Menu.Safe(name)` | a name safe for a menu line (`( ! - / & |` are menu commands) |
| `Menu.AppendLine file, line, header` | one record line; a new file starts with the header |
| `Menu.Explore path, isFolder` | Explorer at a file (selected) or a folder, never waited for; the result says the path |
| `Menu.WinPath(path)` | slashes the Windows way |

The boards (Project Map, On Git or Not: `LIB_DEV/livecode/board_canvas.livecodescript`) use it.
They load it themselves when they build: two folders above the board's stack is the projects
folder, then `LIB_MENU/livecode/lib_menu.livecodescript`. Without it a board still works: plain menus
(no ending), the help bar says "Menus need LIB_MENU", and it writes its records itself.

## Graphic labels, one popup button to rule them all (18 Nov 2026)

The owner's design. A menu title (or, in a game, a sign, a door, a crate) is a plain graphic.
A click on it (mouseUp, never mouseDown: the popup would close again at once) fills ONE hidden popup button on the card with the menu for what was clicked,
and pops it there. Nothing else is a menu button, so no list ever takes the stack's colours:
the popup is plain black on white, set on the template before it is made and again on the button.

```
get Menu.MakeTitle("File", "8,1,50,19")         -- a green title graphic that pops its menu
set the cMenuText of it to "New" & return & "Open"   -- its items (or a menu file of that name)
on menuPopPick pMenu, pItem   -- in the card or stack script: every pick comes here
```

| Handler | Does |
|---|---|
| `Menu.PopFor target, text, at` | pop the target's menu at its bottom-left (`at` = "mouse": at the mouse) |
| `Menu.PopFill(target, text)` | the same, filled but not popped (for tests); the button |
| `Menu.PopButton(object)` | the one popup button of the card, made the first time it is needed |
| `Menu.PopPick item, button` | the popup's own menuPick: sends the pick on (below) |
| `Menu.MakeTitle(menu, rect, ink, paper, group)` | a title graphic, filled so it takes clicks, that pops its menu |

- Which menu: the target's `cMenu`, else its label, else its name.
- Which items: the `text` you pass; else the menu file of that name (`Menu.Text`); else the target's `cMenuText`.
- A pick from a menu file goes to that menu's handler (`Menu.Pick`). Any other pick is sent as
  `menuPopPick menu, item` to the target, and passes up to its card and stack.
- Games: keep the graphics, build the menu when the mouse goes down, from what was clicked.
- The iGame3D XT editor's menu bar works this way now.
- With no screen (a headless test) the popup cannot show: `Menu.PopFor` says "no screen" and the
  button is still filled.

## Menus from files (the owner's iGame3D way)

Menus live per game or app (the owner's 2009 iGame3D layout):

| Folder | Holds |
|---|---|
| `Data/Default/<game or app>/Menus/` (here) | the shipped menus: one text file `<Name>.txt` a menu |
| `Data/Default/<game or app>/Menus/Functions/` (here) | the shipped callbacks the menus call (`*.livecodescript`) |
| `Menus/<game or app>/` in your Data folder | your own menus (`Data.MenuFolder(app)`) |
| `Menus/<game or app>/Functions/` in your Data folder | your own callbacks (`Data.MenuFolder(app, true)`) |

A file of yours wins over the shipped file of the same name, file by file. Copy a shipped file there
and edit it; never edit the shipped set. A Functions file is a plain script file starting
`script "<a name>"`; `Menu.Load` starts using it, so the handlers it holds answer picks from any stack.

```
# a comment
handler: LibraryMenuPick           every pick of this menu goes to this one handler
Library/Open the Data folder       an item, as a path: Head/Sub/Item (the head = the file's name)
Library/-                          a separator
Library/Kinds/kinds:               a submenu filled with the Data folder's kinds
Library/Games/folders: Games       a submenu filled with the folders in Data/Games, when it opens
Library/Wizards/folders: Scripts/Wizards
Library/Data/folders:             "folders:" alone: the folders at the top of the Data folder
```

Drop a folder into `Data/Games`, and the menu grows. Without a `handler:` line the handler is
`<Name>MenuPick`. It gets the whole path (`Library/Games/Antack`) and, for a folder-filled item,
that folder.

| Handler | Does |
|---|---|
| `Menu.Load app` | read the app's shipped menus, then yours over them; start using its callbacks. No name = `Library` |
| `Menu.Reset app` | the shipped set only (your files stay on disk; `Menu.Load` reads them again) |
| `Menu.App()`, `Menu.Functions()` | the app loaded now; each callback file, `Default` or `User`, and where it is |
| `Menu.Loaded()` | each menu, `Default` or `User`, and the file it came from |
| `Menu.Names()`, `Menu.Handler(name)` | the menus loaded; a menu's handler |
| `Menu.Text(name)` | the menu's text for a popup or pulldown button, with the ending |
| `Menu.Pick name, item, object` | the one router: `item` as menuPick gives it (`Games|Antack`) |
| `Menu.Show name, button` | fill a popup button and pop it up |
| `Menu.DefaultFolder(app, functions)`, `Menu.UserFolder(app, functions)`, `Menu.Error()` | where menus come from; why nothing happened |

Your menus need LIB_DATA in use (`Data.MenuFolder`); without it only the shipped set is read.
Example: `Data/Default/Library/Menus/Library.txt` and its `Functions/library_functions.livecodescript`.
A real stack: the iGame3D XT editor's Library menu, `Data/Default/Ig3dEditor/Menus/Library.txt` and its
`Functions/ig3deditor_functions.livecodescript` (a pick on a folder shows it in the editor's own Library
list; only "Explore here..." opens Explorer). Test: `t51_editor_library_menu.txt` (30 checks).

## Tests

`OXT-BEYOND/tests/t43_lib_menu.txt` (headless, no window): 100 checks, all pass on OXT-Beyond's
engine and the 9.6.3 server. It uses a throwaway Data folder (`Data.UseRoot`), never yours.
The boards' test `t39_board_canvas.txt` (89 checks, 6 of them with LIB_MENU absent) runs the boards with this library in a work
folder of its own.

## Licence

GPL-3.0 (see `LICENSE`), because the xTalk work here is built on the GPL-licensed LiveCode Community 9 engine. Copyright (c) 2026 xAction.
