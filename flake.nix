# NixOS system configuration
# --------------------------------------------------------------------------------------------------
{
  description = "System Configuration";

  # ### inputs specifies other flakes to be used in the outputs as dependencies.
  # After inputs are resolved they are passed to the outputs function and map to the explicit and 
  # implicit arguments as defined by the outputs function.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  # ### Implicit arguments
  # In nix function syntax we can require arguments by name explicitly as 'self' is below and using 
  # the '...' allow for additional implicit arguments that will be gathered into a set named 'NAME' 
  # with the '@NAME' syntax. Flake syntax specifies that once 'inputs' are resolved they are passed 
  # to the outputs function as arguments. Thus by naming the implicit arguments '@inputs' we are not 
  # referring to the original inputs attribute set but rather naming the implicit arguments to our 
  # function 'inputs' which happens to also be the name of a flakes inputs attribute set. In the end
  # it works out function the same but is a mistake to conflate the two for general nix cases.
  #
  # ### Explicit arguments
  # Although it is nice to gather all implicit arguments together this means to use them without the 
  # dot notation would require an 'inherit (inputs) nixpkgs' to bring them into scope. Another option 
  # is to just call them out explicitly as required named arguments which does this scoping for you.
  outputs = { self, nixpkgs, ... }@inputs: let

    # Configurable system options
    # ----------------------------------------------------------------------------------------------
    settings = {
      stateVersion = "23.11";           # Base install version, not sure this matters when on flake
      #wmType = if (wm == "hyprland") then "wayland" else "x11";
      term = "alacritty";             # default terminal to use
      fontName = "Intel One Mono";    # default font name
      #fontPkg = pkgs.intel-one-mono;  # default font package
    }
    // import ./flake_opts.nix;         # include configuration set during installation

    # Allow for package patches, overrides and additions
    # * [allowUnfree](https://nixos.wiki/wiki/Unfree_Software)
    # * [lookup-paths](https://nix.dev/tutorials/nix-language.html#lookup-paths)
    # * [Override nixpkgs](https://discourse.nixos.org/t/allowunfree-predicate-does-not-apply-to-self-packages/21734/6)
    # ----------------------------------------------------------------------------------------------
    pkgs = import nixpkgs {
      system = settings.system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;

#      overlays = [
#        (final: prev: {
#          prismlauncher = prev.prismlauncher.override (p: {
#            prismlauncher-unwrapped = p.prismlauncher-unwrapped.overrideAttrs (o: {
#              patches = (o.patches or [ ]) ++ [ ./patches/prismlauncher/offline.patch ];
#            });
#          });
#        })
#      ];
    };

    # Using attribute set update syntax '//' here to combine a couple sets for simpler input arguments
    args = inputs // { inherit settings; } // { iso = false; };
    system = settings.system;
    specialArgs = { inherit args; };
    
  in {
    nixosConfigurations = {

      # Defines configuration for the current system
      system = nixpkgs.lib.nixosSystem {
        inherit pkgs system specialArgs;
        modules = [
          ./hardware-configuration.nix
          (./. + "/profiles" + ("/" + settings.profile + ".nix"))
        ];
      };

      # Defines configuration for building an ISO
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        # Update the args.iso field to be true for ISO builds
        specialArgs = specialArgs // { args = args // { iso = true; }; };
        modules = [ ./profiles/iso/default.nix ];
      };
    };
  };
}
