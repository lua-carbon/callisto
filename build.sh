echo Building Callisto tools...

mkdir bin

{ echo -n 'COMPILED=true;'; cat tools/callisto.lua; } >tools/callisto-temp.lua
glue srlua tools/callisto-temp.lua bin/callisto
chmod +x bin/callisto
rm tools/callisto-temp.lua

echo Building done!