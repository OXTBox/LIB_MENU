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
-- Step 2, menus from files (the owner's iGame3D 2009/2013 way), one set per game or app:
--   LIB_MENU/Data/Default/<game or app>/Menus/            the shipped menus: one text file <Name>.txt a menu
--   LIB_MENU/Data/Default/<game or app>/Menus/Functions/  the shipped callbacks those menus call
--   <Data folder>/Menus/<game or app>/                    the user's own menus (LIB_DATA's Data.MenuFolder(app))
--   <Data folder>/Menus/<game or app>/Functions/          the user's own callbacks (Data.MenuFolder(app, true))
--   A user file wins over the shipped file of the same name, file by file (menus and callbacks alike).
--   A menu file's lines:
--     # a comment
--     handler: LibraryMenuPick     the one handler every pick of this menu goes to (default <Name>MenuPick)
--     Library/Open the Data folder an item, as a path Head/Sub/Item (the head is the file's name)
--     Library/Kinds/Images         a submenu "Kinds" with an item "Images"
--     Library/-                    a separator
--     Library/Games/folders: Games filled at open time with the folders in that Data kind
--     Library/Data/folders:        ("folders:" alone) the folders at the top of the Data folder
--                                  ("folders: Scripts/Wizards" = a subfolder of a kind)
--     Library/Kinds/kinds:         filled with the Data folder's kinds (LIB_DATA's Data.Kinds)
--   Functions/ files are plain xTalk script files, <anything>.livecodescript, starting with
--   script "<a stack name>"; they hold the handlers the menus name (on LibraryMenuPick pPath, pFolder).
--   Menu.Load starts using each one (a library), so a pick reaches its handler from any stack.
--   Menu.Load tApp              read that app's shipped menus, then the user's over them; start using
--                               its callbacks (the user's file wins). No name = "Library" (the old way).
--   Menu.Reset tApp             the shipped set only (the user's files stay on disk, unread)
--   Menu.App()                  the game or app loaded now
--   Menu.Loaded()               name TAB Default|User TAB file, one menu a line
--   Menu.Functions()            file name TAB Default|User TAB file, one callback file a line
--   Menu.Names()                the menus loaded, one a line
--   Menu.Text(tName)            the menu's text for a popup/pulldown button, with the ending
--   Menu.Pick tName, tItem, tObject   one router: sends the menu's handler the whole path
--                               ("Library/Kinds/Images") and, for a folder-filled item, its folder
--   Menu.Show tName, tButton    put the menu's text into a popup button and pop it up
--   Menu.DefaultFolder(tApp, tFunctions), Menu.UserFolder(tApp, tFunctions)  where they come from
--   Menu.Error()                why the last handler did nothing
-- One popup button to rule them all (18 Nov): menu titles are graphics; a click (mouse UP) fills ONE
-- hidden popup button of the card and pops it (plain colours, never the stack's):
--   Menu.PopFor tTarget, tText, tAt   pop tTarget's menu (cMenu, else label, else name) at its
--                               bottom-left (tAt "mouse": at the mouse); tText, else the file menu,
--                               else the target's cMenuText. A pick: menuPopPick tMenu, tItem to
--                               the target (a file menu: Menu.Pick, its own handler)
--   Menu.PopFill(tTarget, tText) the same, filled but not popped (tests); the button's long id
--   Menu.PopButton(tObject)     the one popup button of tObject's card, made on first need
--   Menu.PopPick tItem, tButton the popup's menuPick (routes as above)
--   Menu.MakeTitle(tMenu, tRect, tInk, tPaper, tGroup)  a green graphic title that pops its menu
-- Without LIB_DATA in use the user's part is simply empty: only the shipped set is read.
-- Test hook: Menu.UseFolders tDefault, tUser: the folders that hold <app>/Menus and <app>
-- (empty = the normal ones: LIB_MENU/Data/Default and the Data folder's Menus).

local sMenus       -- name -> array: file, from, handler, lines
local sFilled      -- "Name/Sub/Item" -> the folder a folder-filled item stands for (last Menu.Text)
local sError
local sRestoreQueue  -- the stacks whose mini window was clicked, restored once the click is over
local sTestDefault, sTestUser
local sApp           -- the game or app whose menus are loaded
local sFunctions     -- file name -> array: file, from, stack (the callback libraries in use)

constant kLeave = "Leave comment..."
constant kExplore = "Explore here..."
constant kMini = "Minimize"
constant kMiniWidth = 220    -- the widget's width in pixels
constant kMiniCover = "LIB_MENU_MiniCover"
constant kDefaultApp = "Library"   -- Menu.Load with no name, as before step 0

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

-- the shipped set, beside this library: LIB_MENU/Data/Default/<app>/Menus (+ /Functions)
function Menu.DefaultFolder pApp, pFunctions
   local tPath
   put menuApp(pApp) into pApp
   if pApp is empty then return empty
   if sTestDefault is not empty then
      put sTestDefault into tPath
   else
      put the effective fileName of stack "LIB_MENU" into tPath
      set the itemDelimiter to "/"
      put item 1 to -3 of tPath & "/Data/Default" into tPath
   end if
   put "/" & pApp & "/Menus" after tPath
   if pFunctions is true then put "/Functions" after tPath
   return tPath
end Menu.DefaultFolder

-- the user's own: Menus/<app> (+ /Functions) in the Data folder (empty when LIB_DATA is not in use)
function Menu.UserFolder pApp, pFunctions
   local tPath, tErr
   put menuApp(pApp) into pApp
   if pApp is empty then return empty
   if sTestUser is not empty then
      put sTestUser & "/" & pApp into tPath
      if pFunctions is true then put "/Functions" after tPath
      return tPath
   end if
   try
      put Data.MenuFolder(pApp, pFunctions is true) into tPath
   catch tErr
      put "LIB_DATA (with Data.MenuFolder) is not in use: only the shipped menus" into sError
      return empty
   end try
   return tPath
end Menu.UserFolder

function Menu.App
   return sApp
end Menu.App

command Menu.Reset pApp
   put menuApp(pApp) into pApp
   if pApp is empty then return sError
   put pApp into sApp
   put empty into sMenus
   put empty into sFilled
   menuReadFolder Menu.DefaultFolder(pApp), "Default"
   menuUseFunctions pApp, false
   return empty
end Menu.Reset

command Menu.Load pApp
   put menuApp(pApp) into pApp
   if pApp is empty then return sError
   put pApp into sApp
   put empty into sMenus
   put empty into sFilled
   menuReadFolder Menu.DefaultFolder(pApp), "Default"
   menuReadFolder Menu.UserFolder(pApp), "User"
   menuUseFunctions pApp, true
   return empty
end Menu.Load

function Menu.Functions
   local tNames, tName, tOut
   put the keys of sFunctions into tNames
   sort lines of tNames
   repeat for each line tName in tNames
      put tName & tab & sFunctions[tName]["from"] & tab & sFunctions[tName]["file"] & return after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Menu.Functions

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

-------------------------------------------------------------------- one popup button to rule them all
-- The owner (18 Nov): "graphic labels, one popup button to rule them all". A menu bar (or a game's
-- sign, door, crate...) is plain graphics. A click on one (mouseUp: popping on mouseDown closes it
-- again at once, the owner 18 Nov) fills the ONE hidden popup button
-- of its card with the menu for what was clicked, and pops it there. Nothing else is a menu button,
-- so no dropdown ever takes the stack's colours: the popup's colours are set here, plainly.
--   on mouseUp                            -- in a graphic's script (Menu.MakeTitle writes this)
--      Menu.PopFor the long id of me
--   end mouseUp
--   on menuPopPick pMenu, pItem           -- in the card or stack script: every pick comes here
--      ...
--   end menuPopPick
-- Which menu: the target's cMenu property, else its label, else its short name.
-- Which text: pText when given; else the loaded file menu of that name (Menu.Text); else the
--   target's cMenuText property. A file menu filled here (no pText) is picked through Menu.Pick
--   (its own handler, the ending); anything else sends menuPopPick pMenu, pItem to the target.
--   pItem is as menuPick gives it: "Sub|Item" for a submenu item.

constant kPopName = "LIB_MENU_Popup"
constant kPopInk = "0,0,0"          -- plain black on white, like any system menu
constant kPopPaper = "255,255,255"
constant kPopHilite = "51,153,255"
constant kPopBorder = "128,128,128"

-- the one popup button of the card pObject's stack shows (made on first need, hidden); its long id
function Menu.PopButton pObject
   local tCard, tOld, tBtn, tStack
   put menuCardOf(pObject) into tCard
   if tCard is empty then
      put "no card for " & pObject into sError
      return empty
   end if
   if there is a button kPopName of tCard then
      put the long id of button kPopName of tCard into tBtn
   else
      put the defaultStack into tOld
      lock screen
      lock messages
      put menuStackOf(tCard) into tStack
      set the defaultStack to the short name of tStack
      -- colour the template BEFORE create (owner's rule): nothing is born in the stack's green
      reset the templateButton
      set the textColor of the templateButton to kPopInk
      set the backgroundColor of the templateButton to kPopPaper
      set the hiliteColor of the templateButton to kPopHilite
      set the borderColor of the templateButton to kPopBorder
      set the style of the templateButton to "menu"
      set the menuMode of the templateButton to "popup"
      set the visible of the templateButton to false
      create button kPopName
      put the long id of it into tBtn
      reset the templateButton
      set the defaultStack to tOld
      unlock messages
      unlock screen
   end if
   -- and again on the button itself, every time: nothing inherited, ever
   set the style of tBtn to "menu"
   set the menuMode of tBtn to "popup"
   set the visible of tBtn to false
   set the textColor of tBtn to kPopInk
   set the backgroundColor of tBtn to kPopPaper
   set the hiliteColor of tBtn to kPopHilite
   set the borderColor of tBtn to kPopBorder
   set the traversalOn of tBtn to false
   if the script of tBtn is empty then
      set the script of tBtn to "on menuPick pItem" & return & "   Menu.PopPick pItem, the long id of me" & return & "end menuPick"
   end if
   return tBtn
end Menu.PopButton

-- fill the one popup for pTarget (no popping): the button's long id; Menu.PopFor pops it too
function Menu.PopFill pTarget, pText
   local tBtn, tName, tFile, tErr
   if pTarget is empty or there is not a pTarget then
      put "no target " & pTarget into sError
      return empty
   end if
   put the long id of pTarget into pTarget
   put the cMenu of pTarget into tName
   if tName is empty then
      try
         put the label of pTarget into tName
      catch tErr
         put empty into tName
      end try
   end if
   if tName is empty then put the short name of pTarget into tName
   put false into tFile
   if pText is empty then
      if sMenus[tName] is an array then
         put Menu.Text(tName) into pText
         put true into tFile
      else
         put the cMenuText of pTarget into pText
      end if
   end if
   if pText is empty then
      put "no menu text for " & tName into sError
      return empty
   end if
   put Menu.PopButton(pTarget) into tBtn
   if tBtn is empty then return empty
   set the text of tBtn to pText
   set the cMenuName of tBtn to tName
   set the cMenuTarget of tBtn to pTarget
   set the cMenuFile of tBtn to tFile
   return tBtn
end Menu.PopFill

-- a click (mouseUp) on pTarget: its menu pops at its bottom-left (pAt "mouse": at the mouse)
command Menu.PopFor pTarget, pText, pAt
   local tBtn, tLoc, tErr
   put Menu.PopFill(pTarget, pText) into tBtn
   if tBtn is empty then return sError
   if pAt is "mouse" then
      put the mouseLoc into tLoc
   else
      put the left of pTarget & "," & the bottom of pTarget into tLoc
   end if
   try
      popup tBtn at tLoc
   catch tErr
      put "the popup could not show (no screen?)" into sError
      return "no screen"
   end try
   return empty
end Menu.PopFor

-- the popup's menuPick: to Menu.Pick for a file menu, else menuPopPick pMenu, pItem to the target
-- (a target gone: to the popup's card). The result: what the target said.
command Menu.PopPick pItem, pButton
   local tName, tTarget
   if pButton is empty then put the long id of the target into pButton
   put the cMenuName of pButton into tName
   put the cMenuTarget of pButton into tTarget
   if tTarget is empty or there is not a tTarget then put the long id of the owner of pButton into tTarget
   if the cMenuFile of pButton is true and sMenus[tName] is an array then
      Menu.Pick tName, pItem, tTarget
      return the result
   end if
   dispatch "menuPopPick" to tTarget with tName, pItem
   return it
end Menu.PopPick

-- a green (or pInk) menu title: a graphic with its name showing that pops its menu (cMenu = pMenu)
-- on a click. It is filled (pPaper, default dark green-black) because an unfilled graphic
-- only takes clicks on its outline. pOwner: a group to make it in (empty: the card). Its long id.
function Menu.MakeTitle pMenu, pRect, pInk, pPaper, pOwner
   local tName
   if pInk is empty then put "124,255,124" into pInk
   if pPaper is empty then put "6,16,6" into pPaper
   put "menuTitle_" & pMenu into tName
   reset the templateGraphic
   set the style of the templateGraphic to "rectangle"
   set the foregroundColor of the templateGraphic to pInk
   set the textColor of the templateGraphic to pInk
   set the backgroundColor of the templateGraphic to pPaper
   set the opaque of the templateGraphic to true
   set the lineSize of the templateGraphic to 0
   set the showName of the templateGraphic to true
   if pOwner is empty then
      create graphic tName
   else
      create graphic tName in pOwner
   end if
   reset the templateGraphic
   set the label of it to pMenu
   set the cMenu of it to pMenu
   if pRect is not empty then set the rect of it to pRect
   set the script of it to "on mouseUp" & return & "   Menu.PopFor the long id of me" & return & "end mouseUp"
   return the long id of it
end Menu.MakeTitle

-- the card shown by pObject's stack (where its one popup lives), empty when none
private function menuCardOf pObject
   local tStack
   put menuStackOf(pObject) into tStack
   if tStack is empty then return empty
   return the long id of this card of tStack
end menuCardOf

function Menu.Error
   return sError
end Menu.Error

-------------------------------------------------------------------- private

-- the game or app name: empty = the default app; a path is not a name
private function menuApp pApp
   if pApp is empty then return kDefaultApp
   if pApp contains "/" or pApp contains "\" or pApp is ".." or pApp is "." then
      put "not a game or app name: " & pApp into sError
      return empty
   end if
   return pApp
end menuApp

-- the callback files: stop using the last app's, then start using this app's *.livecodescript
-- (shipped first; a user file of the same name replaces it). A file whose stack name is taken by
-- another file already in memory is skipped, and Menu.Error() says so.
private command menuUseFunctions pApp, pWithUser
   local tName, tA, tFolder, tFrom, tFiles, tFile, tPath, tStack, tLine
   repeat for each key tName in sFunctions
      put sFunctions[tName]["stack"] into tStack
      if tStack is not empty and there is a stack tStack then
         if tStack is among the lines of the stacksInUse then stop using stack tStack
         delete stack tStack
      end if
   end repeat
   put empty into sFunctions
   repeat for each item tFrom in "Default,User"
      if tFrom is "Default" then
         put Menu.DefaultFolder(pApp, true) into tFolder
      else
         if pWithUser is not true then next repeat
         put Menu.UserFolder(pApp, true) into tFolder
      end if
      if tFolder is empty or there is not a folder tFolder then next repeat
      put files(tFolder) into tFiles
      filter tFiles with "*.livecodescript"
      repeat for each line tFile in tFiles
         put tFolder & "/" & tFile into tA[tFile]["file"]
         put tFrom into tA[tFile]["from"]
      end repeat
   end repeat
   repeat for each key tFile in tA
      put tA[tFile]["file"] into tPath
      put line 1 of textDecode(URL ("binfile:" & tPath), "UTF-8") into tLine
      if word 1 of tLine is not "script" then
         put "not a script file (no script line first): " & tPath into sError
         next repeat
      end if
      put word 2 to -1 of tLine into tStack
      replace quote with empty in tStack
      if there is a stack tStack then
         if the effective fileName of stack tStack is not tPath then
            put "stack " & tStack & " is in memory already (another file): " & tPath & " skipped" into sError
            next repeat
         end if
      end if
      start using stack tPath
      put tStack into tA[tFile]["stack"]
      put tA[tFile] into sFunctions[tFile]
   end repeat
end menuUseFunctions

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
      if tKind is empty then
         put Data.Root() into tFolder     -- "folders:" alone: the folders at the top of the Data folder
      else
         put Data.Folder(tKind, tSub) into tFolder
      end if
   catch tErr
      put empty into tFolder
   end try
   if tFolder is not empty then put folders(tFolder) into tList
   filter tList without ".*"
   sort lines of tList
   if tList is empty then
      if tKind is empty then
         put "(nothing in the Data folder yet" & return after xKids[pParent]
      else
         put "(nothing in" && Menu.Safe(word 2 to -1 of pSpec) && "yet" & return after xKids[pParent]
      end if
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
