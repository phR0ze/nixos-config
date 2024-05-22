# Menu options
#
# ### Details
# - https://wiki.xfce.org/howto/customize-menu
# - XFCE's menu is built from a static top level template that then has pre-built categories to 
#   populate with the various menu items.
# - By providing our own toplevel template we can modify the layout
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce;

  menu = lib.mkIf cfg.enable
    (pkgs.writeText "xfce-applications.menu" ''
      <Menu>
          <Name>Xfce</Name>
          <DefaultAppDirs/>
          <DefaultDirectoryDirs/>

          <Include>
              <Category>X-Xfce-Toplevel</Category>
          </Include>

          <Layout>
              <Filename>xfce4-terminal-emulator.desktop</Filename>
              <Filename>xfce4-file-manager.desktop</Filename>
              <Separator/>
              <Menuname>Settings</Menuname>
              <Separator/>
              <Merge type="all"/>
              <Separator/>
              <Filename>dmenu.desktop</Filename>
              <Filename>xfce4-session-logout.desktop</Filename>
          </Layout>

          <Menu>
              <Name>Settings</Name>
              <Directory>xfce-settings.directory</Directory>
              <Include>
                  <Category>Settings</Category>
              </Include>
              <Layout>
                  <Filename>xfce-settings-manager.desktop</Filename>
                  <Separator/>
                  <Merge type="all"/>
              </Layout>
              <Menu>
                  <Name>Screensavers</Name>
                  <Directory>xfce-screensavers.directory</Directory>
                  <Include>
                      <Category>Screensaver</Category>
                  </Include>
              </Menu>
          </Menu>

          <Menu>
              <Name>Accessories</Name>
              <Directory>xfce-accessories.directory</Directory>
              <Include>
                  <Or>
                      <Category>Accessibility</Category>
                      <Category>Core</Category>
                      <Category>Legacy</Category>
                      <Category>Utility</Category>
                  </Or>
              </Include>
              <Exclude>
                  <Or>
                      <Filename>xfce4-file-manager.desktop</Filename>
                      <Filename>xfce4-terminal-emulator.desktop</Filename>
                      <Filename>xfce4-about.desktop</Filename>
                      <Filename>xfce4-run.desktop</Filename>
                  </Or>
              </Exclude>
          </Menu>

          <Menu>
              <Name>Development</Name>
              <Directory>xfce-development.directory</Directory>
              <Include>
                  <Category>Development</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>Education</Name>
              <Directory>xfce-education.directory</Directory>
              <Include>
                  <Category>Education</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>Games</Name>
              <Directory>xfce-games.directory</Directory>
              <Include>
                  <Category>Game</Category>
                  <Category>Games</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>Graphics</Name>
              <Directory>xfce-graphics.directory</Directory>
              <Include>
                  <Category>Graphics</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>Multimedia</Name>
              <Directory>xfce-multimedia.directory</Directory>
              <Include>
                  <Category>Audio</Category>
                  <Category>Video</Category>
                  <Category>AudioVideo</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>Network</Name>
              <Directory>xfce-network.directory</Directory>
              <Include>
                  <Category>Network</Category>
              </Include>
              <Exclude>
                  <Or>
                      <Filename>xfce4-mail-reader.desktop</Filename>
                      <Filename>xfce4-web-browser.desktop</Filename>
                  </Or>
              </Exclude>
          </Menu>

          <Menu>
              <Name>Office</Name>
              <Directory>xfce-office.directory</Directory>
              <Include>
                  <Category>Office</Category>
              </Include>
          </Menu>

          <Menu>
              <Name>System</Name>
              <Directory>xfce-system.directory</Directory>
              <Include>
                  <Or>
                      <Category>Emulator</Category>
                      <Category>System</Category>
                  </Or>
              </Include>
              <Exclude>
                  <Or>
                      <Filename>xfce4-session-logout.desktop</Filename>
                  </Or>
              </Exclude>
          </Menu>

          <DefaultMergeDirs/>
      </Menu>
    '');
in
{
  config = lib.mkIf (cfg.enable) {
    files.all.".config/menus/xfce-applications.menu".link = menu;
  };
}
