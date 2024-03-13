# Sudo configuration
#
# ### Features
# - Passwordless access for whell group
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  security.sudo = {
    enable = true;

    # Configure passwordless sudo access for 'wheel' group
    wheelNeedsPassword = false;

    # Keep the environment variables of the calling user
#    extraConfig = ''
#      Defaults env_keep += "http_proxy HTTP_PROXY"
#      Defaults env_keep += "https_proxy HTTPS_PROXY"
#      Defaults env_keep += "ftp_proxy FTP_PROXY"
#    '';
  };

  files."/root/foobar2".text = "this is a foobar2 test";
}
