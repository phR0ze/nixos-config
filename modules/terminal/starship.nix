# Starship configuration
#
# ### Details
# - 
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  programs.starship = {
    enable = true;
    interactiveOnly = true;

    # Gets stored as a /nix/store package and referred to with the $STARSHIP_CONFIG env variable
    settings = {
      add_newline = false;
      command_timeout = 10000;

      format = lib.concatStrings [
        "$container"
        "$username"
        "[](fg:#0488D3 bg:#606365)"
        "$directory"
        "[](fg:#606365 bg:#1c638d)"
        "$git_branch"
        "$git_status"
        "[ ](fg:#1c638d)"
      ];

#      git_status = {
#        ahead = ">";
#        behind = "<";
#        diverged = "<>";
#        renamed = "r";
#        deleted = "x";
#      };

      container = {
        style = "bg:#0488D3 fg:#FFFFFF";
        format = "[ $name ]($style)";
      };
        
      username = {
        # cyber blue background for user
        style_user = "bg:#0488D3 fg:#FFFFFF";

        # red background for root user
        style_root = "bg:#d31f04 fg:#FFFFFF";

        format = "[ $user ]($style)";
        show_always = true;
        disabled = false;
      };
        
      directory = {
        style = "bg:#606365";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = false;
      };
        
      git_branch = {
        symbol = "";
        style = "bg:#1c638d";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#1c638d";
        ahead = "⇡ $count";
        behind = "⇣ $count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        format = "[$all_status$ahead_behind ]($style)";
      };
    };
  };
}

# vim:set ts=2:sw=2:sts=2
