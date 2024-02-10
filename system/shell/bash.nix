# Minimal bash configuration
#
# ### Features
# - bash
#---------------------------------------------------------------------------------------------------
{ ... }:
let
  aliases = {
    # git aliases
    gb = "git branch -av";
    gd = "git diff --name-only";
    gl = "git log -5 --oneline";
    gf = "vim `git diff --name-only --diff-filter=M | uniq`";

    # misc aliases
    ip = "ip -c";
    ls = "ls -h --group-directories-first --color=auto";
    ll = "ls -lah --group-directories-first --color=auto";
    diff = "diff --color=auto";
    grep = "grep --color=auto";
    free = "free -m";
  };
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = aliases;
  };
}

# vim:set ts=2:sw=2:sts=2
