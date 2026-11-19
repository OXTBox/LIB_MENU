script "Library_MenuFunctions"
-- The callbacks of the Library menu (Library.txt beside this folder). Menu.Load "Library" starts
-- using this file, so a pick reaches LibraryMenuPick from any stack. To change what a pick does,
-- copy this file into your Data folder's Menus/Library/Functions/ and edit the copy: yours wins.

-- pPath: the whole path picked ("Library/Games/Antack"); pFolder: the folder of a folder-filled item
on LibraryMenuPick pPath, pFolder
   local tKind, tErr
   set the itemDelimiter to "/"
   if pFolder is not empty then
      Menu.Explore pFolder, 1
      return the result
   end if
   if pPath is "Library/Open the Data folder" then
      try
         Menu.Explore Data.Root(), 1
      catch tErr
         return "LIB_DATA is not in use"
      end try
      return the result
   end if
   if item 2 of pPath is "Kinds" then
      put item 3 of pPath into tKind
      try
         Menu.Explore Data.Folder(tKind), 1
      catch tErr
         return "LIB_DATA is not in use"
      end try
      return the result
   end if
   pass LibraryMenuPick
end LibraryMenuPick
