local wezterm = require 'wezterm'
local act = wezterm.action

function load_config_table(module_name, default)
  local status, config = pcall(require, module_name)
  if status and type(config) == "table" then
    return config
  else
    return default or {}
  end
end

function hex_to_ansi(hex_color)
    -- Convert hex color #RRGGBB to RGB components
    local r, g, b = hex_color:match("#(%x%x)(%x%x)(%x%x)")

    if r and g and b then
        -- Convert hex to decimal
        r = tonumber(r, 16)
        g = tonumber(g, 16)
        b = tonumber(b, 16)

        -- Create ANSI escape sequence for 24-bit color
        return string.format("\x1b[38;2;%d;%d;%dm", r, g, b)
    else
        -- Return empty string if invalid format
        return ""
    end
end

function colorize(text, color)
    local ansi_color = hex_to_ansi(color)
    local reset = "\x1b[0m"

    if ansi_color ~= "" then
        return ansi_color .. text .. reset
    else
        return text
    end
end

function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end

function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        -- return 'Default Dark (base16)'
        -- return 'Default (dark) (terminal.sexy)'
        -- return 'Builtin Solarized Dark'
        return 'Dracula' -- mostly very good except pre-commit PASSED
        -- return 'Catppuccin Mocha'  # PASSED completely unreadable
        -- return 'Gruvbox Dark'
        -- return 'One Dark (base16)'
        -- return 'monokai'
    else
        return 'Ef-Spring'
    end
end

function shellexpand(path)
    local home = os.getenv("HOME")
    fullpath, n_subs = path:gsub("^~", home)
    return fullpath
end

function make_set(list)  -- oof Lua is verbose sometimes
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end

local function read_lines_from_file(file_path)
    local lines = {}
    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            if line ~= "" then
                table.insert(lines, line)
            end
        end
        file:close()
    end
    return lines
end

local function read_paths_from_file(file_path)
    local paths = {}
    for i, line in ipairs(read_lines_from_file(file_path)) do
        table.insert(paths, shellexpand(line))
    end
    return paths
end

-- Function to format directory path for display
function format_directory_path(file_path)
    local home = os.getenv("HOME")
    local cwd = file_path

    -- Check if it's a string and has a proper format
    if type(cwd) ~= "string" then
        return ""
    end

    -- For file:// URLs (which WezTerm often uses)
    if cwd:find("^file://") then
        -- Remove the file:// prefix
        cwd = cwd:gsub("^file://", "")
    end

    -- If the path is within home directory
    if cwd:find("^" .. home) then
        -- Replace home path with ~
        cwd = "~" .. cwd:sub(#home + 1)
    end

    -- Get last two components
    local components = {}
    for component in cwd:gmatch("[^/]+") do
        table.insert(components, component)
    end

    if #components >= 2 then
        -- If the second-to-last component is "~", only show last component
        if components[#components - 1] == "~" then
            return "~/" .. components[#components]
        else
            -- Otherwise show last two components
            return components[#components - 1] .. "/" .. components[#components]
        end
    elseif #components == 1 then
        return components[1]
    else
        return "/"
    end
end


local config = wezterm.config_builder()
-- Just set a specific theme and nothing else

local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.config = {
    paths = read_paths_from_file(shellexpand("~/.config/wezterm/session-dirs.txt")),
    command_options = {
        fd_path = '/opt/homebrew/bin/fd',
    },
}
sessionizer.apply_to_config(config, true)

-- Set color scheme based on system appearance
config.color_scheme = scheme_for_appearance(get_appearance())
config.colors = {
    background = '#000000',
}

-- config.term = "wezterm"
config.enable_kitty_graphics = false
config.adjust_window_size_when_changing_font_size = false

local function txt_fg_fmt(color, text)
    -- Each format item should have only one key
    return {
        { Foreground = { Color = color } }, -- First set the foreground color
        { Text = text },                    -- Then add the text
        "ResetAttributes"                   -- Then reset attributes
    }
end

local function extend_table(target, source)
    for _, v in ipairs(source) do
        table.insert(target, v)
    end
    return target  -- Return the target for chaining if desired
end

-- Simple string hash function (djb2 algorithm)
local function hash_string(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 2^32
    end
    return hash
end

local color_set = {
    "#FF5555", -- Bright Red
    "#50FA7B", -- Bright Green
    "#F1FA8C", -- Bright Yellow
    "#A66BE0", -- Bright Purple
    "#FF79C6", -- Bright Pink
    "#8BE9FD", -- Bright Cyan
    "#FFB86C", -- Bright Orange
    "#9AEDFE", -- Light Blue
    "#5AF78E", -- Light Green
    "#F4F99D", -- Light Yellow
    "#CAA9FA", -- Light Purple
    "#FF6E67", -- Light Red
    "#ADEDC8", -- Soft Green
    "#FEA44D", -- Soft Orange

    -- Additional colors
    "#F07178", -- Coral
    "#00B1B3", -- Teal
    "#E6DB74", -- Muted Yellow
    "#7DCFFF", -- Sky Blue
    "#D8A0DF", -- Lavender
    "#36C2C2", -- Aqua
    "#FF9E64", -- Peach
    "#85DACC", -- Mint
    "#E3CF65"  -- Gold
}

-- Get a deterministic color for a string
local function get_deterministic_color(str)
    local hash = hash_string(str)
    local index = (hash % #color_set) + 1
    return color_set[index]
end

-- Process color mapping (declarative approach)
local process_colors = {
    emacs = "orange",
    emacsclient = "orange",
    Emacs = 'orange',
    git = "#bb55ff" -- pretty purple
}

local process_replacements = load_config_table('replacements', {})

-- Directory prefix color mapping (declarative approach)
local dir_name_colors = {
    ["apps"] = "cyan",
    ["libs"] = "yellow",
    ["mops"] = 'green',
}

-- Format directory with colored prefixes if applicable
local function format_colored_directory(dir_path)
    local result = {}
    local parts = {}

    -- Split path into components
    for part in dir_path:gmatch("([^/]+)") do
        table.insert(parts, part)
    end

    -- Process each part with coloring as needed
    for i, part in ipairs(parts) do
        if i > 1 then
            table.insert(result, {Text = "/"})
        end

        if dir_name_colors[part] then
            extend_table(result, txt_fg_fmt(dir_name_colors[part], part))
        else
            extend_table(result, txt_fg_fmt(get_deterministic_color(part), part))
        end
    end

    return result
end


local PROCESSES_TO_NOT_PUT_ON_TAB_TITLE = make_set({ 'xonsh', 'mise', 'bash', 'zsh', 'fish', 'starship' })


local function format_tab_title(tab, tabs, panes, config, hover, max_width)
    local process = tab.active_pane.foreground_process_name

    -- Extract just the process name without path
    process = process:gsub("^.*/([^/]+)$", "%1")

    -- some processes are specially-defined by the user and we use those directly
    -- with a known color. This is useful for things like emacs.
    if not process_colors[process] then
        -- but for those that aren't, we prefer the WEZTERM_PROG full command string
        -- over the foreground_process_name.
        if tab.active_pane.user_vars.WEZTERM_PROG then
            process = tab.active_pane.user_vars.WEZTERM_PROG
        end
        for prefix, replacement in pairs(process_replacements) do
            if process:sub(1, #prefix) == prefix then
                process = replacement .. process:sub(#prefix + 1)
                break
            end
        end
    end

    -- Trim leading spaces
    process = process:gsub("^%s+", "")

    if PROCESSES_TO_NOT_PUT_ON_TAB_TITLE[process] then
        process = nil
    end

    local tab_format_items = { { Text = tostring(tab.tab_index + 1) .. " | "} }

    if process then
        -- Apply process coloring based on lookup table
        if process_colors[process] then
            extend_table(tab_format_items, txt_fg_fmt(process_colors[process], process))
        else
            table.insert(tab_format_items, { Text = process })
        end
        table.insert(tab_format_items, { Text = ": " })
    end

    local dir = "<debug?>"
    if tab.active_pane and tab.active_pane.current_working_dir then
        dir = format_directory_path(tab.active_pane.current_working_dir.path)
    end

    -- Apply directory coloring
    extend_table(tab_format_items, format_colored_directory(dir))

    return tab_format_items
end

wezterm.on('format-tab-title', format_tab_title)

-- Set backtick as leader key
config.leader = { key = '`', mods = '', timeout_milliseconds = 1000 }

-- Define keyboard shortcuts that use the leader
config.keys = {
    -- Shift+Enter sends CSI u sequence for Claude Code multi-line input
    { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b[13;2u' },

    -- Add iTerm-like fullscreen toggle
    { key = '0', mods = 'CMD|SHIFT', action = act.ToggleFullScreen },

    -- Sessions (Workspaces)
    { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },
    { key = 'w', mods = 'LEADER', action = sessionizer.show },
    -- create new workspace with name
    { key = 'n', mods = 'LEADER', action = act.PromptInputLine {
          description = 'Enter name for new workspace',
          action = wezterm.action_callback(function(window, pane, line)
                  if line then
                      -- Get current working directory
                      local cwd = pane:get_current_working_dir()

                      -- Switch to a new workspace with the specified name and cwd
                      window:perform_action(
                          act.SwitchToWorkspace {
                              name = line,
                              spawn = {
                                  cwd = cwd.file_path,
                              },
                          },
                          pane
                      )
                  end
          end),
    }},

    -- Rename current workspace
    { key = 'r', mods = 'LEADER', action = act.PromptInputLine
      {
          description = 'Enter new name for current workspace',
          action = wezterm.action_callback(
              function(window, pane, line)
                  if line then
                      window:perform_action(
                          act.RenameWorkspace {
                              name = line,
                          },
                          pane
                      )
                  end
              end
          )
      }
    },

    -- Tabs
    { key = 'c', mods = 'LEADER', action = act.SpawnTab 'DefaultDomain' },
    { key = 'k', mods = 'LEADER', action = act.CloseCurrentTab { confirm = false } },
    { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(-1) },  -- 'arrow left'
    { key = 'o', mods = 'LEADER', action = act.ActivateTabRelative(1) },  -- 'arrow right'
    { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
    { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },
    { key = '0', mods = 'LEADER', action = act.ActivateTab(9) },
    { key = 'LeftArrow', mods = 'LEADER', action = act.MoveTabRelative(-1) },
    { key = 'RightArrow', mods = 'LEADER', action = act.MoveTabRelative(1) },

    -- Make backtick+h send a literal backtick -- i know i'm weird but i like this.
    { key = 'h', mods = 'LEADER', action = act.SendKey { key = '`' } },
    -- backtick+backtick to switch to last tab
    { key = '`', mods = 'LEADER', action = act.ActivateLastTab },

    -- copy mode to be very like emacs
    { key = ' ', mods = 'LEADER', action = act.ActivateCopyMode },
    { key = ' ', mods = 'LEADER|CTRL', action = act.ActivateCopyMode },
}

local my_copy_mode = {
    { key = ' ', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Cell' } },
    { key = 'a', mods = 'CTRL', action = act.CopyMode 'MoveToStartOfLine' },
    { key = 'e', mods = 'CTRL', action = act.CopyMode 'MoveToEndOfLineContent' },
    { key = 'f', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
    { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
    { key = 'w', mods = 'ALT', action = act.Multiple
      {
          { CopyTo = 'ClipboardAndPrimarySelection' },
          -- { CopyMode = 'ScrollToBottom' },
          { CopyMode = 'Close' },
      },
    },
}
local copy_mode = nil
if wezterm.gui then
    copy_mode = wezterm.gui.default_key_tables().copy_mode
    for k, v in pairs(my_copy_mode) do
        table.insert(copy_mode, v)
    end
    config.key_tables = {
        copy_mode =  copy_mode
    }
end

-- Add translucency
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
-- config.window_frame = {
--     font = wezterm.font('JetBrains Mono', size = 14),
-- }
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
-- no ligatures, please


-- function add_theme_colors_to_set()
--     -- Get the default colors (based on your selected color scheme)
--     local colors = wezterm.color.get_builtin_schemes()[config.color_scheme]
--     local bad_colors = { black = 1, white = 1, ['#FFFFFF'] = 1, ['#000000'] = 1, }

--     -- Store the ANSI colors in our global table
--     if colors and colors.ansi then
--         bad_colors[colors.foreground] = 1
--         bad_colors[colors.background] = 1
--         wezterm.log_info("ANSI colors loaded into color_set table:")
--         for i, color in ipairs(colors.ansi) do
--             wezterm.log_info(string.format("ansi[%d]: %s", i, color))
--             if not bad_colors[color] and not color_set[color] then
--                 table.insert(color_set, 1, color)
--             end
--         end
--     end
-- end

function print_colors()
    for i, color in ipairs(color_set) do
        wezterm.log_info('color ' .. tostring(i) .. ' ' .. colorize(color, color))
    end
end

function switch_themes()
    config.color_scheme = scheme_for_appearance(get_appearance())
    print_colors()
    -- add_theme_colors_to_set()
end

wezterm.on('window-config-reloaded', switch_themes)
wezterm.print_colors = print_colors
config.send_composed_key_when_right_alt_is_pressed = true
config.term = 'xterm-256color'
config.scrollback_lines = 10000

-- require("wuake").setup {  -- this does not quite work
--     config = config,
--     config_overrides = {
--         hide_tab_bar_if_only_one_tab = true,
--     }
-- }


local scratch = "_scratch" -- Keep this consistent with Hammerspoon
-- Handler for programmatic workspace switching via escape sequences
-- Usage from shell: printf "\033]1337;SetUserVar=switch_workspace=%s\007" "$(echo -n 'workspace-name' | base64)"
-- WezTerm auto-decodes the base64 value, so we use it directly
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == "switch_workspace" then
    wezterm.log_info("switch_workspace: received value '" .. value .. "'")
    window:perform_action(
      act.SwitchToWorkspace { name = value },
      pane
    )
  end
end)

wezterm.on("gui-attached", function(domain)
  local mux = wezterm.mux
  local workspace = mux.get_active_workspace()
  wezterm.log_info("gui-attached: active workspace is ")
  if workspace ~= scratch then return end

  -- Compute width: 66% of screen width, up to 1000 px
  local width_ratio = 1.0
  local width_max = 2000
  local aspect_ratio = 16 / 9
  local screen = wezterm.gui.screens().active
  local width = math.min(screen.width * width_ratio, width_max)
  local height = width / aspect_ratio

  wezterm.log_info("gui-attached: looking for matching windows")
  for _, window in ipairs(mux.all_windows()) do
    local gwin = window:gui_window()
    if gwin ~= nil then
      wezterm.log_info("gui-attached: found matching window " .. gwin:window_id() .. " for workspace " .. workspace)
      gwin:perform_action(act.SetWindowLevel "AlwaysOnTop", gwin:active_pane())
      gwin:set_inner_size(width, height)
    end
  end
end)

return config
