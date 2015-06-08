@echo off

echo Building Callisto tools...

mkdir bin 2>nul

echo.local COMPILED=true;>tools\callisto-temp.lua
type tools\callisto.lua>>tools\callisto-temp.lua
glue srlua.exe tools\callisto-temp.lua bin\callisto.exe
rm tools\callisto-temp.lua

echo Building done!