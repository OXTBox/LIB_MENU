script "LIB_MENU_OpenIn"
-- LIB_MENU "Open in": a submenu that opens a file in the apps the person wants, built from folders.
-- The owner (19 Nov): "'Open in IDE' needs to be an open in the menu. We may as well 'Open In <App>'
-- and just include a list of applications the user wants to use."
--
--   start using stack "<path>/LIB_MENU/livecode/lib_menu_openin.livecodescript"
--
-- Where the entries live (a later layer wins over an earlier one, entry by entry, by its label):
--   1 shipped   LIB_MENU/Data/Default/Menus/File/Open/
--   2 this PC   <Data folder>/Menus/File/Open/                (everyone who plays on this machine)
--   3 the user  <Data folder>/Users/<user>/Menus/File/Open/   (Menu.OpenInUser; "default" when unset)
--   4 extra     Menu.OpenInAddFolder tFolder (a developer's LIB_USERS/<user>/Data/Menus/File/Open)
-- Inside Open/, one folder per file type, named by the extension in lower case:
--   livecodescript/  txt/  png/  glb/ ...   for those files
--   _all/            for every file          _folder/   for a folder
--   a group named in types.txt ("script: livecodescript lua py") also counts for those types
-- One file = one menu line. Its label is the file name without its extension and without an
-- order number in front ("10 Notepad++.txt" = "Notepad++", placed by 10). Kinds of entry:
--   *.lnk             a Windows shortcut (drag one there from the Start menu): started with the file
--   *.txt             a recipe:  run: <program>   args: "{file}"   window: min   needs: <path>
--                     (no args: line = "{file}"; "args: none" = nothing after the program)
--   *.bat *.cmd       a batch file, given the file as %1 and the line as %2
--   *.ps1             a PowerShell script, given the file and the line (ExecutionPolicy Bypass)
--   *.livecodescript  xTalk: its "on MenuOpenIn pFile, pLine" is sent (an IDE, or an app's own window)
--   "~" in front of a name turns that entry off (it stays there); a name "-" (or "50 -.txt") = a line
-- Placeholders in a recipe's run/args: {file} {folder} {name} {ext} {line} (Windows slashes),
-- %ProgramFiles% %LOCALAPPDATA% %APPDATA% %USERPROFILE% %SystemRoot% (from the environment).
-- "needs: <path>" hides the entry when that path is not there (an app not installed).
-- Open/settings.txt (the last layer that has one wins, line by line):
--   max: 8          more entries than that go into a "More" submenu (0 = never)
--   all: last       where the _all entries go: last, first or off
--   missing: hide   an entry whose "needs:" is not there: hide, or grey (shown, not pickable)
--   edit: on        the last line "Edit this menu..." (Explorer at the user's folder for this type)
--
--   Menu.OpenInText(tFile)        the submenu lines for that file, tab-indented under "Open in"
--   Menu.OpenInItems(tFile)       label TAB kind TAB entry file, one a line, in menu order (no More)
--   Menu.OpenIn tFile, tLabel, tLine   run that entry for the file; the result says what was run
--   Menu.OpenInPick tFile, tItem  the menuPick of a menu made with Menu.OpenInText ("Open in|X",
--                                 "Open in|More|X", "X"); "Edit this menu..." opens the user's folder
--   Menu.OpenInCommand(tFile, tLabel, tLine)  the command line it would run (empty for xTalk)
--   Menu.OpenInUser tName / Menu.OpenInUserName()  whose folder is layer 3
--   Menu.OpenInFolders()          the layers in use, one folder a line
--   Menu.OpenInAddFolder tFolder  / Menu.OpenInClearFolders   layer 4
--   Menu.OpenInRefresh            read the folders again (they are read once, then kept)
--   Paths may come either way round: C:\x, \\wsl$\..., /home/... (all handlers take any);
--   a "/" (or "\") at the end says "a folder" without looking on the disk
--   Menu.OpenInError()            why the last handler did nothing
-- Test hooks: Menu.OpenInUseFolders tShipped, tPC, tUserRoot (folders, empty = the normal ones);
--   Menu.OpenInDry true (never run anything: the result is "would run: ..."; always so off Windows);
--   Menu.OpenInEnv tName, tValue (an environment value for placeholders and needs:).
-- Nothing here is run while a menu is built: only a pick runs, and "start" never waits.

local sError
local sUser
local sExtra
local sDry
local sEnv
local sTestShipped, sTestPC, sTestUserRoot, sTestSet
local sLast        -- the last menu built: ["file"], [label] -> kind TAB entry TAB grey
local sCache       -- folder -> its files ("-" = no such folder), read once (a menu over the WSL bridge stays quick)

constant kOpenIn = "Open in"
constant kMore = "More"
constant kEdit = "Edit this menu..."
constant kKinds = "lnk,txt,bat,cmd,ps1,livecodescript"

-------------------------------------------------------------------- who and where

command Menu.OpenInUser pName
   if pName contains "/" or pName contains "\" or pName is ".." then
      put "not a user name: " & pName into sError
      return sError
   end if
   put pName into sUser
   return empty
end Menu.OpenInUser

function Menu.OpenInUserName
   if sUser is empty then return "default"
   return sUser
end Menu.OpenInUserName

command Menu.OpenInAddFolder pFolder
   if pFolder is among the lines of sExtra then exit Menu.OpenInAddFolder
   put pFolder & return after sExtra
end Menu.OpenInAddFolder

command Menu.OpenInClearFolders
   put empty into sExtra
   put empty into sCache
end Menu.OpenInClearFolders

-- forget what was read from the folders (an entry added or taken away while the app runs)
command Menu.OpenInRefresh
   put empty into sCache
end Menu.OpenInRefresh

command Menu.OpenInUseFolders pShipped, pPC, pUserRoot
   put pShipped into sTestShipped
   put pPC into sTestPC
   put pUserRoot into sTestUserRoot
   put (pShipped is not empty or pPC is not empty or pUserRoot is not empty) into sTestSet
end Menu.OpenInUseFolders

command Menu.OpenInDry pTrue
   put (pTrue is true) into sDry
end Menu.OpenInDry

command Menu.OpenInEnv pName, pValue
   put pValue into sEnv[pName]
end Menu.OpenInEnv

function Menu.OpenInError
   return sError
end Menu.OpenInError

-- the layers, shipped first; folders that are not there are left out
function Menu.OpenInFolders
   local tOut, tF, tRoot, tErr
   -- 1 shipped
   if sTestSet is true then
      put sTestShipped into tF
   else
      put the effective fileName of stack "LIB_MENU_OpenIn" into tF
      set the itemDelimiter to "/"
      put item 1 to -3 of tF & "/Data/Default/Menus/File/Open" into tF
   end if
   if tF is not empty and there is a folder tF then put tF & return after tOut
   -- 2 this PC, 3 the user (both in the Data folder)
   if sTestSet is true then
      put sTestPC into tF
      put sTestUserRoot into tRoot
   else
      try
         put Data.Root() into tRoot
      catch tErr
         put empty into tRoot
      end try
      put empty into tF
      if tRoot is not empty then
         put tRoot & "/Menus/File/Open" into tF
         put tRoot & "/Users" into tRoot
      end if
   end if
   if tF is not empty and there is a folder tF then put tF & return after tOut
   if tRoot is not empty then
      put tRoot & "/" & Menu.OpenInUserName() & "/Menus/File/Open" into tF
      if there is a folder tF then put tF & return after tOut
   end if
   -- 4 extra
   repeat for each line tF in sExtra
      if tF is not empty and there is a folder tF then put tF & return after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Menu.OpenInFolders

-------------------------------------------------------------------- the menu

-- label TAB kind TAB entry file TAB grey(true/false), one a line, in menu order
function Menu.OpenInItems pFile
   local tSet, tTypes, tA, tOrder, tLine, tOut
   put openPath(pFile) into pFile
   put openSettings() into tSet
   put openTypesFor(pFile) into tTypes
   -- the type's own entries (and its groups'), then _all (or first, or not at all)
   if tTypes is not "_folder" then   -- _all is for files; folders have _folder alone
      if tSet["all"] is "first" then put "_all" & return before tTypes
      if tSet["all"] is "last" then put return & "_all" after tTypes
   end if
   openCollect tTypes, tA, tOrder
   sort lines of tOrder numeric by item 1 of each
   repeat for each line tLine in tOrder
      put item 2 to -1 of tLine into tLine
      if tA[tLine]["grey"] is true and tSet["missing"] is "hide" then next repeat
      put tA[tLine]["label"] & tab & tA[tLine]["kind"] & tab & tA[tLine]["file"] & tab & \
            (tA[tLine]["grey"] is true) & return after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Menu.OpenInItems

-- the submenu: "Open in" with the entries one tab in, a "More" submenu past max, the edit line last
function Menu.OpenInText pFile
   local tSet, tItems, tLine, tN, tOut, tMore, tLabel, tShown
   put openPath(pFile) into pFile
   put openSettings() into tSet
   put Menu.OpenInItems(pFile) into tItems
   put empty into sLast
   put pFile into sLast["file"]
   put kOpenIn & return into tOut
   put 0 into tN
   set the itemDelimiter to tab
   repeat for each line tLine in tItems
      put item 1 of tLine into tLabel
      if tLabel is "-" then
         put "-" into tShown
      else
         put openSafe(tLabel) into tShown
         put item 2 to 4 of tLine into sLast[tShown]   -- a pick gives the shown words back
         if item 4 of tLine is true then put "(" before tShown   -- grey: shown, not pickable
         add 1 to tN
      end if
      if tSet["max"] > 0 and tN > tSet["max"] then
         if tLabel is not "-" then
            put tab & tab & tShown & return after tMore
         end if
      else
         put tab & tShown & return after tOut
      end if
   end repeat
   if tItems is empty then put tab & "(nothing set up for this type" & return after tOut
   if tMore is not empty then put tab & kMore & return & tMore after tOut
   if tSet["edit"] is not "off" then put tab & "-" & return & tab & kEdit & return after tOut
   delete the last char of tOut
   return tOut
end Menu.OpenInText

-- a pick from a menu made with Menu.OpenInText; pItem as menuPick gives it
command Menu.OpenInPick pFile, pItem, pLine
   local tLabel
   put openPath(pFile) into pFile
   replace "|" with "/" in pItem
   set the itemDelimiter to "/"
   put item -1 of pItem into tLabel
   if pFile is empty then put sLast["file"] into pFile
   if tLabel is kEdit then
      return openEditFolder(pFile)
   end if
   Menu.OpenIn pFile, tLabel, pLine
   return the result
end Menu.OpenInPick

-------------------------------------------------------------------- running an entry

-- the command line that entry runs for that file (Windows); empty for an xTalk entry or no entry
function Menu.OpenInCommand pFile, pLabel, pLine
   local tE, tKind, tEntry, tR, tWin, tWindow
   put openPath(pFile) into pFile
   put openFind(pFile, pLabel) into tE
   if tE is empty then return empty
   set the itemDelimiter to tab
   put item 1 of tE into tKind
   put openWin(item 2 of tE) into tEntry
   if pLine is empty then put 1 into pLine
   put openWin(pFile) into tWin
   switch tKind
      case "lnk"
         return "start " & quote & quote & " " & quote & tEntry & quote & " " & quote & tWin & quote
      case "bat"
      case "cmd"
         return "start " & quote & quote & " /min cmd /c call " & quote & tEntry & quote & " " & \
               quote & tWin & quote & " " & pLine
      case "ps1"
         return "start " & quote & quote & " /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File " & \
               quote & tEntry & quote & " " & quote & tWin & quote & " " & pLine
      case "txt"
         put openRecipe(item 2 of tE) into tR
         if tR["run"] is empty then return empty
         put empty into tWindow
         if tR["window"] is "min" then put " /min" into tWindow
         if tR["window"] is "max" then put " /max" into tWindow
         if tR["args"] is empty then put quote & "{file}" & quote into tR["args"]
         if tR["args"] is "none" then put empty into tR["args"]
         return "start " & quote & quote & tWindow & " " & quote & openSlash(openFillIn(tR["run"], pFile, pLine)) & quote & \
               " " & openFillIn(tR["args"], pFile, pLine)
   end switch
   return empty
end Menu.OpenInCommand

-- run that entry for that file. The result: "ran: <command>", "would run: <command>" (dry run,
-- or not on Windows), "xTalk: <entry file>", or what went wrong.
command Menu.OpenIn pFile, pLabel, pLine
   local tE, tCmd, tEntry, tErr
   put openPath(pFile) into pFile
   put openFind(pFile, pLabel) into tE
   if tE is empty then
      put "no Open in entry " & pLabel & " for " & pFile into sError
      return sError
   end if
   set the itemDelimiter to tab
   if item 3 of tE is true then
      put pLabel & " is not there on this PC (its needs: line)" into sError
      return sError
   end if
   if pLine is empty then put 1 into pLine
   if item 1 of tE is "livecodescript" then
      put item 2 of tE into tEntry
      try
         dispatch "MenuOpenIn" to stack tEntry with pFile, pLine
      catch tErr
         put "the xTalk entry did not load: " & tEntry into sError
         return sError
      end try
      if it is "unhandled" then
         put "no MenuOpenIn handler in " & tEntry into sError
         return sError
      end if
      return "xTalk: " & tEntry
   end if
   put Menu.OpenInCommand(pFile, pLabel, pLine) into tCmd
   if tCmd is empty then
      put "nothing to run for " & pLabel & " (a recipe needs a run: line)" into sError
      return sError
   end if
   if sDry is true or the platform is not "Win32" then return "would run: " & tCmd
   set the hideConsoleWindows to true
   get shell(tCmd)
   if it is not empty then put it into sError
   return "ran: " & tCmd
end Menu.OpenIn

-------------------------------------------------------------------- private

-- the settings: defaults, then each layer's settings.txt over them
private function openSettings
   local tA, tF, tText, tLine, tKey
   put 8 into tA["max"]
   put "last" into tA["all"]
   put "hide" into tA["missing"]
   put "on" into tA["edit"]
   repeat for each line tF in Menu.OpenInFolders()
      if there is not a file (tF & "/settings.txt") then next repeat
      put openRead(tF & "/settings.txt") into tText
      repeat for each line tLine in tText
         if char 1 of tLine is "#" or not (word 1 of tLine ends with ":") then next repeat
         put char 1 to -2 of word 1 of tLine into tKey
         if tKey is among the items of "max,all,missing,edit" then put word 2 to -1 of tLine into tA[tKey]
      end repeat
   end repeat
   if tA["max"] is not an integer then put 8 into tA["max"]
   return tA
end openSettings

-- the type folders that count for this file, most particular first: its extension, then groups
private function openTypesFor pFile
   local tSuffix, tOut, tF, tText, tLine, tGroup
   -- a folder: there now, or marked by a "/" at the end (a caller who knows, no disk check)
   if the last char of pFile is "/" or there is a folder pFile then return "_folder"
   set the itemDelimiter to "/"
   put item -1 of pFile into tSuffix
   set the itemDelimiter to "."
   if the number of items of tSuffix > 1 then
      put toLower(item -1 of tSuffix) into tSuffix
      put tSuffix into tOut
   else
      put empty into tSuffix
   end if
   if tSuffix is empty then return empty
   repeat for each line tF in Menu.OpenInFolders()
      if there is not a file (tF & "/types.txt") then next repeat
      put openRead(tF & "/types.txt") into tText
      repeat for each line tLine in tText
         if char 1 of tLine is "#" or not (word 1 of tLine ends with ":") then next repeat
         put toLower(char 1 to -2 of word 1 of tLine) into tGroup
         if tSuffix is among the words of toLower(word 2 to -1 of tLine) and not (tGroup is among the lines of tOut) then
            put return & tGroup after tOut
         end if
      end repeat
   end repeat
   return tOut
end openTypesFor

-- every entry of those type folders in every layer; a later layer replaces a label; the first
-- type folder that names a label keeps its place. xOrder: "sortkey,label" lines.
private command openCollect pTypes, @xA, @xOrder
   local tLayer, tType, tF, tFiles, tFile, tParsed, tLabel, tKey, tSeen, tRank, tTypeN, tLine
   put 0 into tTypeN
   repeat for each line tType in pTypes
      if tType is empty then next repeat
      add 1 to tTypeN
      repeat for each line tLayer in Menu.OpenInFolders()
         put tLayer & "/" & tType into tF
         put openListOf(tF) into tFiles
         if tFiles is empty then next repeat
         repeat for each line tFile in tFiles
            if char 1 of tFile is "." then next repeat
            put openParse(tFile) into tParsed
            if tParsed["label"] is empty then next repeat
            put tParsed["label"] into tLabel
            if tLabel is "-" then
               put "-" & tTypeN & "." & tParsed["n"] & "." & tLayer into tKey
            else
               put toLower(tLabel) into tKey
            end if
            if tParsed["off"] is true then
               -- "~Name": a later layer turns an earlier entry off
               if xA[tKey] is an array then put true into xA[tKey]["gone"]
               next repeat
            end if
            if xA[tKey] is not an array then
               -- the first time this label is seen: its place is fixed here
               put tTypeN * 100000 + tParsed["n"] into tRank
               put tRank & "," & tKey & return after xOrder
            end if
            put tLabel into xA[tKey]["label"]
            put tParsed["kind"] into xA[tKey]["kind"]
            put tF & "/" & tFile into xA[tKey]["file"]
            put openMissing(tParsed["kind"], tF & "/" & tFile) into xA[tKey]["grey"]
            put false into xA[tKey]["gone"]
         end repeat
      end repeat
   end repeat
   -- drop what was turned off
   repeat for each line tLine in xOrder
      put item 2 to -1 of tLine into tKey
      if xA[tKey]["gone"] is not true then put tLine & return after tSeen
   end repeat
   put tSeen into xOrder
end openCollect

-- "10 Notepad++.txt" -> n 10, label Notepad++, kind txt; "~VS Code.lnk" -> off; unknown kinds: empty
private function openParse pFile
   local tA, tKind, tName
   set the itemDelimiter to "."
   if the number of items of pFile < 2 then return empty
   put toLower(item -1 of pFile) into tKind
   put item 1 to -2 of pFile into tName
   set the itemDelimiter to comma
   if tKind is "cmd" then put "bat" into tKind
   if not (tKind is among the items of kKinds) then return empty
   put tKind into tA["kind"]
   put false into tA["off"]
   if char 1 of tName is "~" then
      put true into tA["off"]
      delete char 1 of tName
   end if
   put 5000 into tA["n"]
   if word 1 of tName is an integer and the number of words of tName > 1 then
      put word 1 of tName into tA["n"]
      put word 2 to -1 of tName into tName
   end if
   put word 1 to -1 of tName into tA["label"]
   return tA
end openParse

-- true when a recipe's "needs:" path is not there (or a shortcut's own file is gone)
private function openMissing pKind, pEntry
   local tR, tNeed
   if pKind is not "txt" then return false
   put openRecipe(pEntry) into tR
   if tR["needs"] is empty then return false
   put openEnv(tR["needs"]) into tNeed
   if tNeed contains "%" then return true   -- an environment value this PC does not have
   replace "\" with "/" in tNeed
   return not (there is a file tNeed or there is a folder tNeed)
end openMissing

-- a recipe file's keys (run, args, window, needs)
private function openRecipe pEntry
   local tA, tLine, tKey
   repeat for each line tLine in openRead(pEntry)
      if char 1 of tLine is "#" or not (word 1 of tLine ends with ":") then next repeat
      put toLower(char 1 to -2 of word 1 of tLine) into tKey
      if tKey is among the items of "run,args,window,needs" then put word 2 to -1 of tLine into tA[tKey]
   end repeat
   return tA
end openRecipe

-- %NAME% from the environment (or Menu.OpenInEnv); unknown names stay as they are
private function openEnv pText
   local tName, tValue, tA, tB, tSkip
   put 0 into tSkip
   repeat 20 times
      put offset("%", pText, tSkip) into tA
      if tA is 0 then exit repeat
      add tSkip to tA
      put offset("%", pText, tA) into tB
      if tB is 0 then exit repeat
      add tA to tB
      put char tA + 1 to tB - 1 of pText into tName
      put empty into tValue
      if sEnv[tName] is not empty then
         put sEnv[tName] into tValue
      else if tName is among the items of "ProgramFiles,LOCALAPPDATA,APPDATA,USERPROFILE,SystemRoot,ProgramData" then
         put value("$" & tName) into tValue
      end if
      if tValue is empty then
         put tB into tSkip   -- unknown: left as it is
      else
         put tValue into char tA to tB of pText
         put tA - 1 + the number of chars of tValue into tSkip
      end if
   end repeat
   return pText
end openEnv

-- a program path: Windows slashes, a /mnt/c path as C:\ (never \\wsl$: a program there will not start)
private function openSlash pPath
   if pPath begins with "/mnt/" and char 7 of pPath is "/" then
      put toUpper(char 6 of pPath) & ":" & char 7 to -1 of pPath into pPath
   end if
   replace "/" with "\" in pPath
   return pPath
end openSlash

private function openFillIn pText, pFile, pLine
   local tFolder, tName, tSuffix
   if the last char of pFile is "/" and the number of chars of pFile > 3 then delete the last char of pFile
   put openEnv(pText) into pText
   set the itemDelimiter to "/"
   put item 1 to -2 of pFile into tFolder
   put item -1 of pFile into tName
   set the itemDelimiter to "."
   put empty into tSuffix
   if the number of items of tName > 1 then put item -1 of tName into tSuffix
   replace "{file}" with openWin(pFile) in pText
   replace "{folder}" with openWin(tFolder) in pText
   replace "{name}" with tName in pText
   replace "{ext}" with tSuffix in pText
   replace "{line}" with pLine in pText
   return pText
end openFillIn

-- Windows slashes; /mnt/c/... as C:\...; any other WSL path (/home/...) as \\wsl$\Ubuntu\home\...
private function openWin pPath
   if the last char of pPath is "/" and the number of chars of pPath > 3 then delete the last char of pPath
   if pPath begins with "/mnt/" and char 7 of pPath is "/" and char 6 of pPath is among the chars of "abcdefghijklmnopqrstuvwxyz" then
      put toUpper(char 6 of pPath) & ":" & char 7 to -1 of pPath into pPath
   else if char 1 of pPath is "/" and char 2 of pPath is not "/" then
      put "//wsl$/Ubuntu" before pPath
   end if
   replace "/" with "\" in pPath
   return pPath
end openWin

-- the entry for that label in the last menu built for that file (else built now): kind TAB file TAB grey
private function openFind pFile, pLabel
   local tLine
   if sLast["file"] is pFile and sLast[pLabel] is not empty then return sLast[pLabel]
   set the itemDelimiter to tab
   repeat for each line tLine in Menu.OpenInItems(pFile)
      if item 1 of tLine is pLabel then return item 2 to 4 of tLine
   end repeat
   return empty
end openFind

-- the user's folder for this file's type (made now), opened in Explorer
private function openEditFolder pFile
   local tTypes, tLast, tF, tRoot, tErr
   put line 1 of openTypesFor(pFile) into tTypes
   if tTypes is empty then put "_all" into tTypes
   if sTestSet is true then
      put sTestUserRoot into tRoot
   else
      try
         put Data.Root() & "/Users" into tRoot
      catch tErr
         put empty into tRoot
      end try
   end if
   if tRoot is empty then
      put "no Data folder (LIB_DATA not in use): no user folder to edit" into sError
      return sError
   end if
   put tRoot & "/" & Menu.OpenInUserName() & "/Menus/File/Open/" & tTypes into tF
   openMakeFolder tF
   put empty into sCache   -- the person is about to add or take away entries
   try
      Menu.Explore tF, 1
      put the result into tErr
   catch tErr
      put "Path: " & tF into tErr
   end try
   return tErr
end openEditFolder

private command openMakeFolder pFolder
   local tSoFar, tSeg
   set the itemDelimiter to "/"
   repeat for each item tSeg in pFolder
      put tSeg & "/" after tSoFar
      if tSoFar is "/" or there is a folder tSoFar then next repeat
      create folder tSoFar
   end repeat
end openMakeFolder

-- a folder's files, sorted, from the cache (empty: no folder or nothing in it)
private function openListOf pFolder
   local tFiles
   if sCache[pFolder] is empty then
      if there is a folder pFolder then
         put files(pFolder) into tFiles
         sort lines of tFiles
         put "+" & return & tFiles into sCache[pFolder]
      else
         put "-" into sCache[pFolder]
      end if
   end if
   if sCache[pFolder] is "-" then return empty
   return line 2 to -1 of sCache[pFolder]
end openListOf

-- one form inside: forward slashes ("\\wsl$\Ubuntu\x" -> "//wsl$/Ubuntu/x", "C:\x" -> "C:/x")
private function openPath pPath
   replace "\" with "/" in pPath
   return pPath
end openPath

private function openRead pFile
   local tText
   put textDecode(URL ("binfile:" & pFile), "UTF-8") into tText
   replace numToChar(13) with empty in tText
   return tText
end openRead

-- like Menu.Safe, without needing LIB_MENU loaded
private function openSafe pText
   local tC
   -- "/" (shortcut key), "&" (underlined letter) and "|" (submenu path) anywhere; "(" (greyed),
   -- "!" (tick) and "-" (a line) only matter in front
   repeat for each item tC in "&,|,/"
      replace tC with " " in pText
   end repeat
   repeat while char 1 of pText is among the items of "(,!,-, "
      delete char 1 of pText
   end repeat
   return pText
end openSafe
