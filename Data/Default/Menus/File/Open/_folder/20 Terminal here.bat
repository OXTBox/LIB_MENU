@echo off
rem Open in > Terminal here: a command window in that folder (start makes it stay open;
rem pushd gives a \\wsl$ folder a drive letter: cmd cannot stand in a \\server\ path, /d fell back to C:\Windows).
start "Terminal" cmd /k pushd "%~1"
