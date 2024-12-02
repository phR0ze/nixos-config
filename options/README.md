# options
I'm defining options as configuration parameters that won't have any effect until they are enabled 
and used as part of a profile. Additionally all options are imported by default recursively at the 
top level making it easier conditionally to check if certain options are enabled.

On the flip side I'm defining profiles and modules to be where the options are actually being enabled 
and used. Thus you'll see both a `options/development/vscode` and a `modules/development/vscode`. 
This helps when thinking about behavior logically.

<!-- 
vim: ts=2:sw=2:sts=2
-->
