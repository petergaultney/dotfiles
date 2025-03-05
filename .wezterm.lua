local wezterm = require 'wezterm'
local act = wezterm.action

return {
  -- Set backtick as leader key
  leader = { key = '`', mods = '', timeout_milliseconds = 1000 },

  -- Define keyboard shortcuts that use the leader
  keys = {
    -- Sessions (Workspaces)
    { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },
    { key = 'n', mods = 'LEADER', action = act.SwitchWorkspaceRelative(1) },
    { key = 'p', mods = 'LEADER', action = act.SwitchWorkspaceRelative(-1) },
    { key = 'c', mods = 'LEADER', action = act.PromptInputLine {
      description = 'Enter name for new workspace',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            act.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    }},

    -- Tabs
    { key = 't', mods = 'LEADER', action = act.SpawnTab 'DefaultDomain' },
    { key = 'w', mods = 'LEADER', action = act.CloseCurrentTab { confirm = true } },
    { key = '[', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'LEADER', action = act.ActivateTabRelative(1) },
    { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },
    { key = '0', mods = 'LEADER', action = act.ActivateTab(9) },
    -- Add more numbers as needed

    -- Make backtick+backtick send a literal backtick
    { key = '`', mods = 'LEADER', action = act.SendKey { key = '`' } },
  },

  -- Add translucency
  window_background_opacity = 0.85, -- Adjust value between 0.0 (fully transparent) and 1.0 (opaque)

  -- Optional: Add blur for better readability with transparency
  macos_window_background_blur = 20,
}
