# XFCE keyboard shortcuts options
#
# ### Details
# - Contains shortcuts for both the Window Manager settings and the general keyboard settings
# - Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.shortcuts;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  xmlfile = lib.mkIf (xfceCfg.enable)
    (pkgs.writeText "shortcuts.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>

      <channel name="xfce4-keyboard-shortcuts" version="1.0">
        <property name="commands" type="empty">
          <property name="default" type="empty">
            <property name="&lt;Alt&gt;F1" type="empty"/>
            <property name="&lt;Alt&gt;F2" type="empty">
              <property name="startup-notify" type="empty"/>
            </property>
            <property name="&lt;Alt&gt;F3" type="empty">
              <property name="startup-notify" type="empty"/>
            </property>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;l" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="empty"/>
            <property name="XF86Display" type="empty"/>
            <property name="&lt;Super&gt;p" type="empty"/>
            <property name="&lt;Primary&gt;Escape" type="empty"/>
            <property name="XF86WWW" type="empty"/>
            <property name="HomePage" type="empty"/>
            <property name="XF86Mail" type="empty"/>
            <property name="Print" type="empty"/>
            <property name="&lt;Alt&gt;Print" type="empty"/>
            <property name="&lt;Shift&gt;Print" type="empty"/>
            <property name="&lt;Super&gt;e" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;f" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Escape" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;Escape" type="empty"/>
            <property name="&lt;Super&gt;r" type="empty">
              <property name="startup-notify" type="empty"/>
            </property>
            <property name="&lt;Alt&gt;&lt;Super&gt;s" type="empty"/>
          </property>
          <property name="custom" type="empty">
            <property name="&lt;Alt&gt;Print" type="string" value="xfce4-screenshooter -w"/>
            <property name="&lt;Super&gt;r" type="string" value="${cfg.appFinderCmd}">
              <property name="startup-notify" type="bool" value="true"/>
            </property>
            <property name="Print" type="string" value="xfce4-screenshooter"/>
            <property name="&lt;Shift&gt;Print" type="string" value="xfce4-screenshooter -r"/>
            <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>
            <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>
            <property name="override" type="bool" value="true"/>
            <property name="&lt;Super&gt;t" type="string" value="alacritty"/>
            <property name="&lt;Super&gt;f" type="string" value="thunar"/>
            <property name="&lt;Super&gt;e" type="string" value="code"/>
            <property name="&lt;Super&gt;w" type="string" value="firefox"/>
            <property name="&lt;Super&gt;j" type="string" value="jellyfinmediaplayer"/>
            <property name="&lt;Super&gt;o" type="string" value="libreoffice"/>
            <property name="&lt;Super&gt;x" type="string" value="xfce4-session-logout"/>
            <property name="&lt;Super&gt;l" type="string" value="xflock4"/>
            <property name="&lt;Primary&gt;Escape" type="string" value="xfce4-taskmanager"/>
            <property name="&lt;Super&gt;Escape" type="string" value="xkill"/>
            <property name="&lt;Super&gt;Page_Down" type="string" value="wmctl place halfh bottom-left"/>
            <property name="&lt;Super&gt;Page_Up" type="string" value="wmctl place halfh top-left"/>
            <property name="&lt;Super&gt;Return" type="string" value="wmctl place large top-right"/>
            <property name="&lt;Super&gt;Delete" type="string" value="wmctl place small bottom-left"/>
            <property name="&lt;Super&gt;End" type="string" value="wmctl place small bottom-right"/>
            <property name="&lt;Super&gt;Insert" type="string" value="wmctl place small top-left"/>
            <property name="&lt;Super&gt;Home" type="string" value="wmctl place  small top-right"/>
            <property name="&lt;Super&gt;equal" type="string" value="wmctl shape grow"/>
            <property name="&lt;Super&gt;minus" type="string" value="wmctl shape shrink"/>
            <property name="&lt;Super&gt;Left" type="string" value="wmctl place halfw top-left"/>
            <property name="&lt;Super&gt;Right" type="string" value="wmctl place halfw top-right"/>
            <property name="${cfg.dropDownTerminalKey}" type="string" value="xfce4-terminal --hide-menubar --drop-down"/>
            <property name="${cfg.appMenuKey}" type="string" value="xfce4-popup-applicationsmenu"/>
          </property>
        </property>
        <property name="xfwm4" type="empty">
          <property name="default" type="empty">
            <property name="&lt;Alt&gt;Insert" type="empty"/>
            <property name="Escape" type="empty"/>
            <property name="Left" type="empty"/>
            <property name="Right" type="empty"/>
            <property name="Up" type="empty"/>
            <property name="Down" type="empty"/>
            <property name="&lt;Alt&gt;Tab" type="empty"/>
            <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="empty"/>
            <property name="&lt;Alt&gt;Delete" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Down" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Left" type="empty"/>
            <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="empty"/>
            <property name="&lt;Alt&gt;F4" type="empty"/>
            <property name="&lt;Alt&gt;F6" type="empty"/>
            <property name="&lt;Alt&gt;F7" type="empty"/>
            <property name="&lt;Alt&gt;F8" type="empty"/>
            <property name="&lt;Alt&gt;F9" type="empty"/>
            <property name="&lt;Alt&gt;F10" type="empty"/>
            <property name="&lt;Alt&gt;F11" type="empty"/>
            <property name="&lt;Alt&gt;F12" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;End" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Home" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_1" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_2" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_3" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_4" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_5" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_6" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_7" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_8" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;KP_9" type="empty"/>
            <property name="&lt;Alt&gt;space" type="empty"/>
            <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Right" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;d" type="empty"/>
            <property name="&lt;Primary&gt;&lt;Alt&gt;Up" type="empty"/>
            <property name="&lt;Super&gt;Tab" type="empty"/>
            <property name="&lt;Primary&gt;F1" type="empty"/>
            <property name="&lt;Primary&gt;F2" type="empty"/>
            <property name="&lt;Primary&gt;F3" type="empty"/>
            <property name="&lt;Primary&gt;F4" type="empty"/>
            <property name="&lt;Primary&gt;F5" type="empty"/>
            <property name="&lt;Primary&gt;F6" type="empty"/>
            <property name="&lt;Primary&gt;F7" type="empty"/>
            <property name="&lt;Primary&gt;F8" type="empty"/>
            <property name="&lt;Primary&gt;F9" type="empty"/>
            <property name="&lt;Primary&gt;F10" type="empty"/>
            <property name="&lt;Primary&gt;F11" type="empty"/>
            <property name="&lt;Primary&gt;F12" type="empty"/>
            <property name="&lt;Super&gt;KP_Left" type="empty"/>
            <property name="&lt;Super&gt;KP_Right" type="empty"/>
            <property name="&lt;Super&gt;KP_Down" type="empty"/>
            <property name="&lt;Super&gt;KP_Up" type="empty"/>
            <property name="&lt;Super&gt;KP_Page_Up" type="empty"/>
            <property name="&lt;Super&gt;KP_Home" type="empty"/>
            <property name="&lt;Super&gt;KP_End" type="empty"/>
            <property name="&lt;Super&gt;KP_Next" type="empty"/>
          </property>
          <property name="custom" type="empty">
            <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>
            <property name="Right" type="string" value="right_key"/>
            <property name="Down" type="string" value="down_key"/>
            <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>
            <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>
            <property name="Up" type="string" value="up_key"/>
            <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>
            <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>
            <property name="Escape" type="string" value="cancel_key"/>
            <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>
            <property name="&lt;Primary&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>
            <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>
            <property name="Left" type="string" value="left_key"/>
            <property name="override" type="bool" value="true"/>
            <property name="${cfg.maximizeWindowKey}" type="string" value="maximize_window_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;1" type="string" value="move_window_workspace_1_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;2" type="string" value="move_window_workspace_2_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;3" type="string" value="move_window_workspace_3_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;4" type="string" value="move_window_workspace_4_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;5" type="string" value="move_window_workspace_5_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;6" type="string" value="move_window_workspace_6_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;7" type="string" value="move_window_workspace_7_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;8" type="string" value="move_window_workspace_8_key"/>
            <property name="&lt;Alt&gt;&lt;Super&gt;9" type="string" value="move_window_workspace_9_key"/>
            <property name="${cfg.showDesktopKey}" type="string" value="show_desktop_key"/>
            <property name="${cfg.nextWorkspaceKey}" type="string" value="next_workspace_key"/>
            <property name="&lt;Super&gt;1" type="string" value="workspace_1_key"/>
            <property name="&lt;Super&gt;2" type="string" value="workspace_2_key"/>
            <property name="&lt;Super&gt;3" type="string" value="workspace_3_key"/>
            <property name="&lt;Super&gt;4" type="string" value="workspace_4_key"/>
            <property name="&lt;Super&gt;5" type="string" value="workspace_5_key"/>
            <property name="&lt;Super&gt;6" type="string" value="workspace_6_key"/>
            <property name="&lt;Super&gt;7" type="string" value="workspace_7_key"/>
            <property name="&lt;Super&gt;8" type="string" value="workspace_8_key"/>
            <property name="&lt;Super&gt;9" type="string" value="workspace_9_key"/>
            <property name="&lt;Shift&gt;&lt;Super&gt;ISO_Left_Tab" type="string" value="prev_workspace_key"/>
            <property name="${cfg.minimizeWindowKey}" type="string" value="hide_window_key"/>
          </property>
        </property>
        <property name="providers" type="array">
          <value type="string" value="xfwm4"/>
          <value type="string" value="commands"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.shortcuts = {
      dropDownTerminalKey = lib.mkOption {
        type = types.str;
        default = "F12";
        description = lib.mdDoc "Drop down terminal shortcut";
      };
      maximizeWindowKey = lib.mkOption {
        type = types.str;
        default = "&lt;Super&gt;Up";
        description = lib.mdDoc "Maximize the current window";
      };
      minimizeWindowKey = lib.mkOption {
        type = types.str;
        default = "&lt;Super&gt;Down";
        description = lib.mdDoc "Minimize the current window";
      };
      showDesktopKey = lib.mkOption {
        type = types.str;
        default = "&lt;Super&gt;m";
        description = lib.mdDoc "Hide all windows, showing the desktop";
      };
      nextWorkspaceKey = lib.mkOption {
        type = types.str;
        default = "&lt;Super&gt;Tab";
        description = lib.mdDoc "Switch to the next workspace";
      };
      appMenuKey = lib.mkOption {
        type = types.str;
        default = "&lt;Super&gt;space";
        description = lib.mdDoc "Activate the applications menu";
      };
      appFinderCmd = lib.mkOption {
        type = types.str;
        default = if config.apps.utils.dmenu.enable then config.apps.utils.dmenu.run else "xfce4-appfinder -c";
        description = lib.mdDoc "App finder command to use";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfceCfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".copy = xmlfile;
  };

}
