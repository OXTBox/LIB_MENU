script "LIB_MENU"
-- LIB_MENU: one way to make menus in every stack (rules: LIB_MENU/PLAN.md).
--
--   start using stack "<path>/LIB_MENU/livecode/lib_menu.livecodescript"
--
-- Step 1, the rules every menu follows:
--   Menu.End()                  the ending: a separator, "Leave comment...", "Explore here...", "Minimize"
--   Menu.WithEnd(tMenu)         a menu's text with the ending after it (no menu writes it itself)
--   Menu.IsEnd(tItem)           true for the three ending lines
--   Menu.EndPick tItem, tTarget, tObject   sends menuLeaveComment / menuExploreHere tTarget to tObject;
--                               "Minimize" LIB_MENU does itself (Menu.Minimize tObject's stack)
--   Menu.Minimize tObject       the window of tObject's stack shrinks to a small widget (the whole app,
--                               scaled down); any mouse down on it brings it back (Menu.Restore)
--   Menu.Restore tObject        back to the size and place it had; Menu.IsMini(tObject) true while small
--   Menu.Safe(tName)            a name made safe for a menu line (no ( ! - / & | commands)
--   Menu.AppendLine tFile, tLine, tHeader  one record line; a new file starts with tHeader
--   Menu.Explore tPath, tIsFolder          Explorer at a file (selected) or a folder, never waited for
--   Menu.WinPath(tPath)         slashes turned the Windows way
--
-- Step 2, menus from files (the owner's iGame3D 2009/2013 way):
--   one menu = one text file <Name>.txt; the shipped set is LIB_MENU/Menus/Default, the user's own
--   files in the Data folder (Data.Folder("Scripts", "Menus")) win over it file by file.
--   A menu file's lines:
--     # a comment
--     handler: LibraryMenuPick     the one handler every pick of this menu goes to (default <Name>MenuPick)
--     Library/Open the Data folder an item, as a path Head/Sub/Item (the head is the file's name)
--     Library/Kinds/Images         a submenu "Kinds" with an item "Images"
--     Library/-                    a separator
--     Library/Games/folders: Games filled at open time with the folders in that Data kind
--                                  ("folders: Scripts/Wizards" = a subfolder of a kind)
--     Library/Kinds/kinds:         filled with the Data folder's kinds (LIB_DATA's Data.Kinds)
--   Menu.Load                   read the Default set, then the user's files over it
--   Menu.Reset                  the Default set only (the user's files stay on disk, unread)
--   Menu.Loaded()               name TAB Default|User TAB file, one menu a line
--   Menu.Names()                the menus loaded, one a line
--   Menu.Text(tName)            the menu's text for a popup/pulldown button, with the ending
--   Menu.Pick tName, tItem, tObject   one router: sends the menu's handler the whole path
--                               ("Library/Kinds/Images") and, for a folder-filled item, its folder
--   Menu.Show tName, tButton    put the menu's text into a popup button and pop it up
--   Menu.Error()                why the last handler did nothing
-- Test hook: Menu.UseFolders tDefault, tUser (empty = the normal folders).

local sMenus       -- name -> array: file, from, handler, lines
local sFilled      -- "Name/Sub/Item" -> the folder a folder-filled item stands for (last Menu.Text)
local sError
local sRestoreQueue  -- the stacks whose mini window was clicked, restored once the click is over
local sTestDefault, sTestUser

constant kLeave = "Leave comment..."
constant kExplore = "Explore here..."
constant kMini = "Minimize"
constant kMiniWidth = 220    -- the widget's width in pixels
constant kMiniCover = "LIB_MENU_MiniCover"

-------------------------------------------------------------------- step 1: the ending

function Menu.End
   return "-" & return & kLeave & return & kExplore & return & kMini
end Menu.End

function Menu.WithEnd pMenu
   if pMenu is not empty and the last char of pMenu is not return then put return after pMenu
   return pMenu & Menu.End()
end Menu.WithEnd

function Menu.IsEnd pItem
   return pItem is kLeave or pItem is kExplore or pItem is kMini
end Menu.IsEnd

-- the stack that owns the menu answers: on menuLeaveComment pTarget / on menuExploreHere pTarget
command Menu.EndPick pItem, pTarget, pObject
   if pObject is empty then put the long id of the target into pObject
   switch pItem
      case kLeave
         dispatch "menuLeaveComment" to pObject with pTarget
         break
      case kExplore
         dispatch "menuExploreHere" to pObject with pTarget
         break
      case kMini
         Menu.Minimize pObject
         return "handled"
      default
         put "not an ending line: " & pItem into sError
         return "unhandled"
   end switch
   return it
end Menu.EndPick

-------------------------------------------------------------------- the ending: Minimize
-- The owner (18 Nov): "Minimize to a small widget sized window with a menu option at the bottom of
-- our popup and then pop the stack back to full size with any mousedown on the mini window."
-- The window keeps showing the whole app, scaled down (its scaleFactor), under a clear cover that
-- takes the next mouse down. The size and place it had are kept on the stack (cMenuMini...).

command Menu.Minimize pObject
   local tStack, tSF, tTL, tOld, tCard
   put menuStackOf(pObject) into tStack
   if tStack is empty then
      put "no stack for " & pObject into sError
      exit Menu.Minimize
   end if
   if Menu.IsMini(tStack) then exit Menu.Minimize
   put the scaleFactor of tStack into tSF
   put the topLeft of tStack into tTL
   set the cMenuMiniSF of tStack to tSF
   set the cMenuMiniTL of tStack to tTL
   put the defaultStack into tOld
   lock screen
   lock messages
   set the defaultStack to the short name of tStack
   create graphic kMiniCover
   set the style of it to "rectangle"
   set the rect of it to the rect of this card
   set the opaque of it to true
   set the lineSize of it to 0
   set the backgroundColor of it to "40,40,48"
   set the blendLevel of it to 80
   set the tooltip of it to "Click to bring the window back"
   set the script of it to "on mouseDown" & return & "   Menu.Restore the long id of me" & return & \
         "end mouseDown" & return & "on mouseUp" & return & "end mouseUp" & return & \
         "on mouseDoubleDown" & return & "end mouseDoubleDown" & return & \
         "on mouseDoubleUp" & return & "end mouseDoubleUp"
   set the cMenuMiniCover of tStack to the long id of it
   set the defaultStack to tOld
   set the scaleFactor of tStack to min(tSF, kMiniWidth / the width of tStack)
   set the topLeft of tStack to tTL
   unlock messages
   unlock screen
end Menu.Minimize

function Menu.IsMini pObject
   local tStack
   put menuStackOf(pObject) into tStack
   if tStack is empty then return false
   return the cMenuMiniSF of tStack is not empty
end Menu.IsMini

-- from the cover's mouseDown: the cover cannot be deleted while its own script runs, so the
-- window comes back a moment later, when the click is over
command Menu.Restore pObject
   local tStack
   put menuStackOf(pObject) into tStack
   if tStack is empty then exit Menu.Restore
   if tStack is not among the lines of sRestoreQueue then put tStack & return after sRestoreQueue
   send "menuRestoreQueued" to me in 0 milliseconds
end Menu.Restore

on menuRestoreQueued
   local tStack, tQueue
   put sRestoreQueue into tQueue
   put empty into sRestoreQueue
   repeat for each line tStack in tQueue
      if there is a tStack then menuRestoreNow tStack
   end repeat
end menuRestoreQueued

private command menuRestoreNow pStack
   local tCover, tSF, tTL
   put the cMenuMiniSF of pStack into tSF
   if tSF is empty then exit menuRestoreNow
   put the cMenuMiniTL of pStack into tTL
   put the cMenuMiniCover of pStack into tCover
   lock screen
   lock messages
   if tCover is not empty then
      if there is a tCover then delete tCover
   end if
   set the scaleFactor of pStack to tSF
   set the topLeft of pStack to tTL
   set the cMenuMiniSF of pStack to empty
   set the cMenuMiniTL of pStack to empty
   set the cMenuMiniCover of pStack to empty
   unlock messages
   unlock screen
end menuRestoreNow

-- the stack a control, card or stack belongs to (its long id), empty when there is none
private function menuStackOf pObject
   local tObj
   put pObject into tObj
   repeat while tObj is not empty
      if there is not a tObj then return empty
      if word 1 of the long id of tObj is "stack" then return the long id of tObj
      put the long id of the owner of tObj into tObj
   end repeat
   return empty
end menuStackOf

-- menu text treats ( ! - / & and | as commands: keep them out of labels
function Menu.Safe pText
   replace "&" with "+" in pText
   replace "/" with numToCodepoint(8725) in pText -- a division slash: looks like / but is no menu command
   replace "|" with "-" in pText
   replace tab with " " in pText
   replace return with " " in pText
   if char 1 of pText is among the items of "(,!,-" then put " " before pText
   return pText
end Menu.Safe

-------------------------------------------------------------------- step 1: records and Explorer

-- append one line (UTF-8) to a record file; a new file starts with pHeader (its lines as given)
command Menu.AppendLine pFile, pLine, pHeader
   local tText
   if there is a file pFile then
      put textDecode(URL ("binfile:" & pFile), "UTF-8") into tText
   else if pHeader is not empty then
      put pHeader into tText
   end if
   if tText is not empty and the last char of tText is not return then put return after tText
   put pLine & return after tText
   put textEncode(tText, "UTF-8") into URL ("binfile:" & pFile)
   if the result is not empty then
      put "could not write " & pFile & ": " & the result into sError
      return sError
   end if
   return empty
end Menu.AppendLine

function Menu.WinPath pPath
   replace "/" with "\" in pPath
   return pPath
end Menu.WinPath

-- Explorer with a file selected, or a folder opened; "start" returns at once, so nothing waits on
-- the WSL bridge. pIsFolder 1 or 0 when the caller knows (no disk check); empty = look now.
-- The result says what happened, for the stack's help line.
command Menu.Explore pPath, pIsFolder
   local tWin, tCmd
   if pIsFolder is empty then
      if there is a folder pPath then
         put 1 into pIsFolder
      else
         put 0 into pIsFolder
      end if
   end if
   put Menu.WinPath(pPath) into tWin
   if the platform is not "Win32" then return "Path:" && tWin
   set the hideConsoleWindows to true
   if pIsFolder is 1 then
      put "start " & quote & quote & " explorer.exe " & quote & tWin & quote into tCmd
   else
      put "start " & quote & quote & " explorer.exe /select," & quote & tWin & quote into tCmd
   end if
   get shell(tCmd)
   return "Explorer:" && tWin
end Menu.Explore

-------------------------------------------------------------------- step 2: menus from files

command Menu.UseFolders pDefault, pUser
   put pDefault into sTestDefault
   put pUser into sTestUser
end Menu.UseFolders

-- the shipped set, beside this library: LIB_MENU/Menus/Default
function Menu.DefaultFolder
   local tPath
   if sTestDefault is not empty then return sTestDefault
   put the effective fileName of stack "LIB_MENU" into tPath
   set the itemDelimiter to "/"
   return item 1 to -3 of tPath & "/Menus/Default"
end Menu.DefaultFolder

-- the user's own menus: Scripts/Menus in the Data folder (empty when LIB_DATA is not in use)
function Menu.UserFolder
   local tPath, tErr
   if sTestUser is not empty then return sTestUser
   try
      put Data.Folder("Scripts", "Menus") into tPath
   catch tErr
      put "LIB_DATA is not in use: only the Default menus" into sError
      return empty
   end try
   return tPath
end Menu.UserFolder

command Menu.Reset
   put empty into sMenus
   put empty into sFilled
   menuReadFolder Menu.DefaultFolder(), "Default"
end Menu.Reset

command Menu.Load
   local tUser
   Menu.Reset
   put Menu.UserFolder() into tUser
   if tUser is not empty then menuReadFolder tUser, "User"
end Menu.Load

function Menu.Loaded
   local tName, tOut
   repeat for each line tName in Menu.Names()
      put tName & tab & sMenus[tName]["from"] & tab & sMenus[tName]["file"] & return after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Menu.Loaded

function Menu.Names
   local tNames
   put the keys of sMenus into tNames
   sort lines of tNames
   return tNames
end Menu.Names

function Menu.Handler pName
   return sMenus[pName]["handler"]
end Menu.Handler

-- the text for a popup or pulldown button, built now (folders are read now), with the ending
function Menu.Text pName
   local tKids, tLine, tAt, tRel, tSpec, tParent, tOut
   if sMenus[pName] is not an array then
      put "no menu " & pName & " (Menu.Load first?)" into sError
      return Menu.End()
   end if
   put empty into sFilled
   repeat for each line tLine in sMenus[pName]["lines"]
      put menuRelPath(tLine) into tRel
      if tRel is empty then next repeat
      put menuSpecAt(tRel) into tAt
      if tAt > 0 then
         put char tAt to -1 of tRel into tSpec
         put empty into tParent
         if tAt > 2 then put char 1 to tAt - 2 of tRel into tParent
         menuAddPath tKids, tParent
         menuFill tKids, pName, tParent, tSpec
      else
         menuAddPath tKids, tRel
      end if
   end repeat
   put menuEmit(tKids, empty, empty) into tOut
   return Menu.WithEnd(tOut)
end Menu.Text

-- one router for every file menu. pItem as menuPick gives it ("Kinds|Images"), or a whole path.
-- The ending lines go to Menu.EndPick; anything else to the menu's one handler, with the whole
-- path and, for a folder-filled item, its folder. The result: what dispatch said.
command Menu.Pick pName, pItem, pObject
   local tPath, tLast
   replace "|" with "/" in pItem
   if pName is empty then
      set the itemDelimiter to "/"
      put item 1 of pItem into pName
      put item 2 to -1 of pItem into pItem
   end if
   if pObject is empty then put the long id of the target into pObject
   put pName & "/" & pItem into tPath
   set the itemDelimiter to "/"
   put item -1 of pItem into tLast
   if Menu.IsEnd(tLast) then
      Menu.EndPick tLast, tPath, pObject
      return the result
   end if
   if sMenus[pName] is not an array then
      put "no menu " & pName into sError
      return "unhandled"
   end if
   dispatch sMenus[pName]["handler"] to pObject with tPath, sFilled[tPath]
   return it
end Menu.Pick

command Menu.Show pName, pButton
   set the text of pButton to Menu.Text(pName)
   popup pButton at the mouseLoc
end Menu.Show

function Menu.Error
   return sError
end Menu.Error

-------------------------------------------------------------------- private

-- every <Name>.txt of a folder; a later folder's file replaces an earlier one of the same name
private command menuReadFolder pFolder, pFrom
   local tFiles, tFile, tName, tText, tLine, tA
   if pFolder is empty or there is not a folder pFolder then exit menuReadFolder
   put files(pFolder) into tFiles
   filter tFiles with "*.txt"
   repeat for each line tFile in tFiles
      set the itemDelimiter to "."
      put item 1 to -2 of tFile into tName
      put empty into tA
      put pFolder & "/" & tFile into tA["file"]
      put pFrom into tA["from"]
      put tName & "MenuPick" into tA["handler"]
      put textDecode(URL ("binfile:" & tA["file"]), "UTF-8") into tText
      replace numToChar(13) with empty in tText
      repeat for each line tLine in tText
         put word 1 to -1 of tLine into tLine
         if tLine is empty or char 1 of tLine is "#" then next repeat
         if tLine begins with "handler:" then
            put word 2 of tLine into tA["handler"]
         else
            put tLine & return after tA["lines"]
         end if
      end repeat
      put tName into tA["name"]
      put tA into sMenus[tName]
   end repeat
end menuReadFolder

-- where a "folders:" or "kinds:" step starts in a path (it may hold "/" itself), or 0
private function menuSpecAt pRel
   local tKey, tAt
   repeat for each item tKey in "folders:,kinds:"
      if pRel begins with tKey then return 1
      put offset("/" & tKey, pRel) into tAt
      if tAt > 0 then return tAt + 1
   end repeat
   return 0
end menuSpecAt

-- a line's path without its head: "Library/Kinds/Images" -> "Kinds/Images"; a line with no "/"
-- is an item of the menu itself
private function menuRelPath pLine
   set the itemDelimiter to "/"
   if the number of items of pLine < 2 and not (pLine ends with "/") then return pLine
   return item 2 to -1 of pLine
end menuRelPath

-- put each step of a path under its parent once (separators every time), in the file's order
private command menuAddPath @xKids, pRel
   local tSoFar, tSeg, tParent
   set the itemDelimiter to "/"
   put empty into tSoFar
   repeat for each item tSeg in pRel
      if tSeg is empty then next repeat
      put tSoFar into tParent
      if tSoFar is empty then
         put tSeg into tSoFar
      else
         put "/" & tSeg after tSoFar
      end if
      if tSeg is "-" or not (tSeg is among the lines of xKids[tParent]) then
         put tSeg & return after xKids[tParent]
      end if
   end repeat
end menuAddPath

-- "folders: Games" / "folders: Scripts/Wizards": the folders there now; "kinds:": the Data kinds
private command menuFill @xKids, pName, pParent, pSpec
   local tKind, tSub, tFolder, tList, tItem, tLabel, tKey, tLine, tErr
   if word 1 of pSpec is "kinds:" then
      try
         put Data.Kinds() into tList
      catch tErr
         put "(LIB_DATA is not in use" & return into xKids[pParent]
         exit menuFill
      end try
      repeat for each line tLine in tList
         put item 1 of tLine & return after xKids[pParent]
      end repeat
      exit menuFill
   end if
   put word 2 to -1 of pSpec into tKind
   set the itemDelimiter to "/"
   put item 2 to -1 of tKind into tSub
   put item 1 of tKind into tKind
   try
      put Data.Folder(tKind, tSub) into tFolder
   catch tErr
      put empty into tFolder
   end try
   if tFolder is not empty then put folders(tFolder) into tList
   filter tList without ".*"
   sort lines of tList
   if tList is empty then
      put "(nothing in" && Menu.Safe(word 2 to -1 of pSpec) && "yet" & return after xKids[pParent]
      exit menuFill
   end if
   repeat for each line tItem in tList
      put Menu.Safe(tItem) into tLabel
      if pParent is empty then
         put pName & "/" & tLabel into tKey
      else
         put pName & "/" & pParent & "/" & tLabel into tKey
      end if
      put tFolder & "/" & tItem into sFilled[tKey]
      put tLabel & return after xKids[pParent]
   end repeat
end menuFill

-- the tree as menu text: a submenu's lines one tab further in
private function menuEmit @xKids, pParent, pIndent
   local tSeg, tOut, tPath
   repeat for each line tSeg in xKids[pParent]
      put pIndent & tSeg & return after tOut
      if tSeg is "-" then next repeat
      if pParent is empty then
         put tSeg into tPath
      else
         put pParent & "/" & tSeg into tPath
      end if
      if xKids[tPath] is not empty then put menuEmit(xKids, tPath, pIndent & tab) after tOut
   end repeat
   return tOut
end menuEmit
