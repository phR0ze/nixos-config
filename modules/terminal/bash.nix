# Minimal bash configuration
#
# ### Details
# - These changes get saved in /etc/bashrc which is loaded by /etc/profile
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
    # Installs dircolors and adds `eval "$(/nix/store/.../coreutils-9.3/bin/dircolors -b)"`
    enableLsColors = true;
    enableCompletion = true;

    # Adds these to the bottom of /etc/bashrc
    shellAliases = aliases;

    # Enable starship
    # promptInit = ''
    #   eval "$(${pkgs.starship}/bin/starship init bash)"
    # '';

    # Adds in the middle of /etc/bashrc
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

    shellInit = ''
      complete -cf sudo                   # Setup bash tab completion for sudo
      set -o vi                           # Set vi command prompt editing
      umask 022                           # Default permissions for the files you create

      shopt -s dotglob                    # Have * include .files as well
      shopt -s extglob                    # Include extended globbing support
      shopt -s histappend                 # Append to the history file, don't overwrite it
      shopt -s checkwinsize               # Update window LINES/COLUMNS after ea. command if necessary

      export HISTSIZE=10000               # Set history length
      export HISTFILESIZE=${HISTSIZE}     # Set history file size
      export HISTCONTROL=ignoreboth       # Ignore duplicates and lines starting with space
      export EDITOR=vim                   # Set the editor to use
      export VISUAL=vim                   # Set the editor to use
      export KUBE_EDITOR=vim              # Set the editor to use for Kubernetes edit commands

      export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
    '';

    #loginShellInit = ''

    #interactiveShellInit = ''
  };
}

# vim:set ts=2:sw=2:sts=2
