# Profiles
Profiles in this context are being defined as top level NixOS modules that pre-define a system for a 
pre-determined purpose. Profiles essentially allow you to custom tailor configuration for your 
specific purpose, i.e. maybe a theater focused system, or a minimal server or your daily runner 
desktop. With profiles you can have a new system up and running in minutes exactly the way you wanted 
it. No more painfully pieceing together your perfect system to have it get bricked or fried and 
having to start all over.

## Pre-defined profiles
These are the pre-defined profiles that can be used in the root `flake.nix` by setting the 
`settings.profile` variable e.g. `profile = "xfce/desktop";`. I've crafted the profiles in such a way 
that most build on a prior one including more packages and configuration for their specific use case.

The desktop environment is such a pervasive choice that I've built out different profiles based on 
different desktop environment selections.

### XFCE based profiles
* [xfce/desktop](xfce/desktop) - heavy full development desktop environment, builds on `netbook`
* [xfce/netbook](xfce/netbook) - medium weight system targeting netbooks, mini-pcs etc.., builds on `lite`
* [xfce/theater](xfce/theater) - lean-back media experience for your TV, builds on `lite`
* [xfce/server](xfce/server) - server XFCE environment, builds on `lite`
* [xfce/lite](xfce/lite) - minimal XFCE environment, build on `shell`

### Standard profiles
The standard profiles don't make opinionated GUI choices like which desktop environment, 
window manager or compositor to use. This makes them reusable as building blocks for other profiles. 

* [shell](shell) - minimal bash system, builds on `core`
* [core](core) - minimal environment meant as a container starter

<!-- 
vim: ts=2:sw=2:sts=2
-->
