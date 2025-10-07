# Service management functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: {

  # Extract the target service and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target service's name used for user name and group
  # - uid: is the specific target service's user id
  # - gid: is the specific target service's group id
  #-------------------------------------------------------------------------------------------------
  getService = args: name: uid: gid: let
    target = args.services.oci."${name}" or {};
    service = {
      enable = target.enable or false;
      name = target.name or name;
      tag = if ((target.tag or "") != "") then target.tag else "latest";
      user = {
        name = target.user.name or name;
        group = target.user.group or name;
        pass = target.user.pass;
        fullname = target.user.fullname or name;
        email = target.user.email or "${name}@local";
        uid = target.user.uid or uid;
        gid = target.user.gid or gid;
      };
      port = target.port or 80;
    };
  in service;

  # Create a user for a containerized application to use. This is useful for setting the permissions 
  # on the /var/lib/APP directory to something that can be read by the container user.
  # - user: user object of the form { name; group; uid; gid }
  #-------------------------------------------------------------------------------------------------
  createUser = user: {
    name = user.name;
    isNormalUser = true;
    uid = user.uid;
    group = user.group;

    # Assign the app user space to use, defaults to 0700 permission
    home = "/var/lib/${user.name}";
    createHome = true;
  };

  # Create a group for a containerized application to use. This is useful for setting the permissions 
  # on the /var/lib/APP directory to something that can be read by the container user.
  # - user: user object of the form { name; group; uid; gid }
  createGroup = user: {
    gid = user.gid;
  };

  # Create systemd service for podman network creation
  # - name: name of the network to create e.g. `immich`
  #-------------------------------------------------------------------------------------------------
  createContNetwork = name: {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = [
        "${pkgs.podman}/bin/podman network rm -f ${name}"
      ];
    };
    script = ''
      if ! ${pkgs.podman}/bin/podman network exists ${name}; then
        ${pkgs.podman}/bin/podman network create --interface-name ${name} ${name}
      fi
    '';
  };

  # Extend systemd service for podman app service. By using the same name as the originally generated 
  # systemd service by the `oci-container` directive we can simply include more configuration for 
  # that service such as the dependency on the podman network it is to use.
  # - name: name of the podman-SUFFIX to use
  # - deps: an optional argument that when given are additional dependency services
  #-------------------------------------------------------------------------------------------------
  extendContService = { name, deps ? null }: rec {

    # Don't start this container unless the required services start
    requires = [
      "podman-network-${name}.service"
    ] ++ lib.optionals (deps != null) (map (x: "podman-${name}-${x}.service") deps);

    # Only start this container after these services
    after = [
      "podman-network-${name}.service"
    ] ++ lib.optionals (deps != null) (map (x: "podman-${name}-${x}.service") deps);

    serviceConfig = {
      Restart = "always";
      WorkingDirectory = "/var/lib/${name}";
    };
  };
}
