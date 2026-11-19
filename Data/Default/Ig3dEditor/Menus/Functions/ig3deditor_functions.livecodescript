script "Ig3dEditor_MenuFunctions"
-- The callbacks of the iGame3D XT editor's Library menu (Library.txt beside this folder).
-- Menu.Load "Ig3dEditor" starts using this file, so a pick reaches Ig3dEditorLibraryPick. The
-- editor sends the pick to its card, so "the target" is the editor's card: these lines only say
-- which of the editor's own handlers answers. To change what a pick does, copy this file into
-- your Data folder's Menus/Ig3dEditor/Functions/ and edit the copy: yours wins.

-- pPath: the whole path picked ("Library/Models", "Library/Games/Antack");
-- pFolder: for an item filled from a folder (Data, Games), that folder on disk
on Ig3dEditorLibraryPick pPath, pFolder
   set the itemDelimiter to "/"
   if pFolder is not empty then
      -- show what is in it, in the editor's own Library list (Explorer only when asked)
      dispatch "Ig.ShowFolder" to the target with pFolder
      exit Ig3dEditorLibraryPick
   end if
   -- the editor's own items (Models, Levels, Text, ..., Set Data Folder...), as they always were
   dispatch "Ig.Menu" to the target with "Library", item -1 of pPath
end Ig3dEditorLibraryPick
