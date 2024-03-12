# Minimal bash configuration
#
# ### Details
# - These changes get saved in /etc/bashrc which is loaded by /etc/profile
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
{
  environment.variables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
  };

  programs.bash = {

    # Configures 'dircolors -b' but doesn't allow for a custom config so manually doing this below.
    enableLsColors = false;

    # Installs 'bash_completion' package and configures it in '/etc/bashrc'.
    enableCompletion = true;

    # Adds this to /etc/profile for all shells
    shellInit = ''
      umask 022                           # Default permissions for the files you create
      shopt -s dotglob                    # Have * include .files as well
      shopt -s extglob                    # Include extended globbing support
    '';

    # Bash prompt
    # - Using green prompt for admin and red for user in dumb TERM cases
    # - Using starship configuration for smart TERMs. The 'programs.starship' option only checks for 
    #   'dumb' TERM so manually handling this myself here for more flexibility.
    promptInit = ''
      # Dumb term default
      PROMPT_COLOR="1;31m"
      ((UID)) && PROMPT_COLOR="1;32m"
      PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "

      # Smart term starship
      if [[ "$TERM" != "dumb" && "$TERM" != "linux" ]]; then
        export STARSHIP_CONFIG=${
          pkgs.writeText "starship.toml"
          (lib.fileContents ../../include/.config/starship.toml)
        }
        eval "$(${pkgs.starship}/bin/starship init bash)"
      fi
    '';

    # Adds this to the /etc/bashrc
    interactiveShellInit = ''
      complete -cf sudo                   # Setup bash tab completion for sudo
      set -o vi                           # Set vi command prompt editing
      shopt -s histappend                 # Append to the history file, don't overwrite it
      shopt -s checkwinsize               # Update window LINES/COLUMNS after ea. command if necessary

      export HISTSIZE=10000               # Set history length
      export HISTFILESIZE=$HISTSIZE       # Set history file size
      export HISTCONTROL=ignoreboth       # Ignore duplicates and lines starting with space
      export EDITOR=vim                   # Set the editor to use
      export VISUAL=vim                   # Set the editor to use
      export KUBE_EDITOR=vim              # Set the editor to use for Kubernetes edit commands

      export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
    '';

    # Adds to /etc/bashrc lower down
    promptPluginInit = ''
      # Configure dircolors which is installed with 'coreutils-full'
      eval "$(dircolors -b ${pkgs.writeText ".dircolors" (lib.fileContents ../../include/.dircolors)})"
    '';

    # Adds this to the /etc/profile as well
    #loginShellInit = ''
    #'';

    # Adds these to the bottom of /etc/bashrc
    shellAliases = {
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
  };
}
