-- Initialization entry point
-- By creating my own plugin and placing it in the pack/$NAME/start folder I've created an entry 
-- point that will automatically get run by the system to then run my custom configuration 
-- ../../lua/init.lua which then sources everything from ../../lua/config. This allows me to get an 
-- automatically run configuration that is entirely based in lua and grouped together nicely in my 
-- Nix configuration providing full Lua syntax hilighting and support while working on the 
-- configuration rather than trying to fit it inline into Nix strings without those niceties.
require("init")
