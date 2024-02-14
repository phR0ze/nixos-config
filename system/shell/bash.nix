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
    enableLsColors = true;
    enableCompletion = true;
    shellAliases = aliases;
    promptInit = ''
      if [ "$TERM" != "dumb" ]; then
        if [ "$TERM" == "xterm"]; then
          PS1="\[\033]2;\h:\u:\w\007\]$PS1"
        else
          PROMPT_COLOR="1;31m"
          ((UID)) && PROMPT_COLOR="1;32m"
          PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
        fi
      fi
    '';
  };
}

# vim:set ts=2:sw=2:sts=2
