script "LIB_MENU_OpenIn_IDE"
-- Open in > IDE: the script file in the xTalk IDE's script editor, when the app runs inside an IDE
-- (OXT-Beyond, LiveCode). In a built app (no IDE) it hands the file to whatever Windows opens it with.
-- A user who wants a particular IDE started instead adds a recipe beside this one in their own
-- folder, e.g. livecodescript/06 OXT-Beyond.txt:  run: V:\APPS\OXT-Beyond-0.2.7\OXT-Beyond.exe

on MenuOpenIn pFile, pLine
   local tStack
   if the environment is "development" then
      put the short name of stack pFile into tStack
      edit the script of stack tStack
      return "edited " & tStack
   end if
   launch document pFile
   return "launched " & pFile
end MenuOpenIn
