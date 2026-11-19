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

## Tests

`OXT-BEYOND/tests/t43_lib_menu.txt` (headless, no window): 88 checks, all pass on OXT-Beyond's
engine and the 9.6.3 server. It uses a throwaway Data folder (`Data.UseRoot`), never yours.
The boards' test `t39_board_canvas.txt` (89 checks, 6 of them with LIB_MENU absent) runs the boards with this library in a work
folder of its own.
