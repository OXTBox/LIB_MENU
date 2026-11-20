# LIB_MENU: "Open in"

19 Nov 2026, by Claude (Opus 5.5). Branch `menu-open-in`, waiting for the owner.

The owner: "'Open in IDE' needs to be an open in the menu. We may as well 'Open In <App>' and just
include a list of applications the user wants to use. ...think about several options that menu
could get cluttered with and we'll see what happens in the menu and folders, use the V:\ drive to
simulate a users custom folder, and the scripts they would need to add themselves."

## How it works

A submenu **Open in** for any file (or folder), filled from folders. One file = one menu line.

```
Menus/File/Open/
  settings.txt        max: 8 / all: last / missing: hide / edit: on
  types.txt           script: livecodescript lua py ...   (a group folder counts for those types)
  livecodescript/     entries for .livecodescript files
  script/             entries for every type in the "script" group
  _all/               entries for every file
  _folder/            entries for folders
    10 Notepad++.txt          a recipe:  run: <program>  args: "{file}"  needs: <path>
    20 Notepad++ at line.bat  a batch file: %1 = the file, %2 = the line
    21 Blender (import).ps1   a PowerShell script: the file, the line
    30 WordPad.lnk            a Windows shortcut dragged in from the Start menu
    05 IDE.livecodescript     xTalk: on MenuOpenIn pFile, pLine
    ~Notepad.txt              "~" = this line is off (here: switches off a shipped Notepad)
    60 -.txt                  a line across the menu
```

The number in front sets the place; the rest of the name is the words in the menu.

Four layers, a later one wins label by label:

| # | Folder | Who |
|---|---|---|
| 1 | `LIB_MENU/Data/Default/Menus/File/Open/` | shipped: IDE (script files), Notepad, Default app, Explorer |
| 2 | `<Data>/Menus/File/Open/` | this PC: everyone who plays on it |
| 3 | `<Data>/Users/<user>/Menus/File/Open/` | one person (`Menu.OpenInUser`) |
| 4 | any folder given with `Menu.OpenInAddFolder` | e.g. a developer's `LIB_USERS/<user>/Data/Menus/File/Open/` |

The last line of the submenu, **Edit this menu...**, opens the person's own folder for that file
type in Explorer (made if missing): that is how a user adds an app, no editor needed.

Code: `livecode/lib_menu_openin.livecodescript` (handlers listed at its top). It does not touch
`lib_menu.livecodescript`; no stack uses it yet. Test: `OXT-BEYOND/tests/t62_open_in.txt`,
46 checks, all pass on both engines (t43 and t51 still pass).

## The V: simulation (`V:\Users\Public\Documents\Data`)

| Where | Who | What it shows |
|---|---|---|
| `Menus\File\Open\` | this PC | Blender for models, Paint.NET for images, both with `needs:` |
| `Users\default\` | dana-like | nothing of her own: the shipped lines + this PC's |
| `Users\alex\Menus\File\Open\` | alex (modder) | a **crowded** menu: VS Code at the line, OXT-Beyond, Notepad++ at line (.bat), Blender import (.ps1), Copy path, Copy WSL path, 7-Zip, SHA-256, Copy to Desktop, Terminal here, WSL bash here; `max: 6` |
| `Users\kenji\Menus\File\Open\` | kenji (kanji user folder, code page 932) | Sakura Editor (.bat with `chcp 65001`), a UTF-8 check before Notepad (.ps1) |
| `Users\jordan\Menus\File\Open\` | jordan (work PC, scripts locked) | only `.lnk` shortcuts; `all: off`; `missing: grey` shows an app IT hasn't installed yet, greyed |

Each user folder has a README.txt saying what that person had to do and why.

## What happened in the menus (alex, a .livecodescript file)

```
Open in
    IDE                      shipped (xTalk: the IDE's script editor)
    VS Code                  alex, recipe, -g file:line
    Notepad++ at line        alex, .bat (group "script")
    Default app              shipped (_all)
    Copy path                alex (_all)
    Copy WSL path            alex (_all)
    More
        7-Zip archive
        SHA-256
        Notepad++            (also "Notepad++ at line" above: two Notepad++ lines, his choice)
        Copy to Desktop
        Explorer
    -
    Edit this menu...
```

Clutter, and what the folders offer against it:

1. **Too many lines**: `max:` puts the rest under "More". Alex's 12 lines became 6 + More.
2. **"Every file" lines drown the type's own**: `all: last` (default), `first`, or `off` (jordan).
3. **Apps not installed**: `needs:` hides the line (`missing: hide`) or greys it (`missing: grey`).
4. **Versioned install folders** (`Blender Foundation\Blender 5.2\`): an update hides the line
   silently. Alex's .ps1 looks for the newest Blender instead. A recipe can't; a script can.
5. **The same app twice** (Notepad++ for scripts and for every file): two labels, two lines. Same
   label = one line (the later layer wins), so naming decides.
6. **Shipped lines a user doesn't want**: `~Notepad.txt` in their folder; nothing is deleted.
7. **Names that are menu commands** (`/ & |`, a leading `( ! -`) are turned into spaces; brackets
   inside a name are kept ("Blender (import)").
8. **Actions that aren't apps** (Copy path, SHA-256, Copy to Desktop, Terminal here) fit the same
   folders. They may want their own submenu later ("Do" / "Send to"?).

What users have to write themselves, and why:

- **Go to a line**: each app has its own switch (`-n7`, `-g file:7`, `-Y=7`): a recipe's `args:` or a .bat.
- **Make the app do something, not just open**: Blender won't open a .glb from the command line,
  it needs `--python-expr` with an import call (alex's .ps1).
- **Non-English paths**: batch files need `chcp 65001` (kenji); PowerShell copes.
- **Locked-down PCs**: no scripts at all (group policy beats `-ExecutionPolicy Bypass`): shortcuts only (jordan).

## Tried for real on Windows

Alex's Copy path and Copy WSL path (.ps1) gave the right paths on the clipboard; SHA-256's hash
works. Not tried: the menu inside a stack (no stack uses it yet), the recipes, .lnk and .bat lines
through `shell()` in OXT-Beyond, the IDE line.

## For the owner

1. Should **Open in** be part of the ending of every menu (with Leave comment / Explore here /
   Minimize) whenever the thing clicked is a file? [suggested: yes]
2. Which stack gets it first? [suggested: the iGame3D XT editor's Library list, then the boards]
3. Your own entries: `Data\Users\<you>\...` on each PC, or `LIB_USERS\<you>\Data\Menus\File\Open`
   in the projects (layer 4)? Both work now.
