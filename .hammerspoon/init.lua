-- .config/hammerspoon/init.lua
Logger = hs.logger.new("default", "info")
local scratch = "_scratch" -- keep this consitent with Wezterm
local wez = {}

function wez.spawn(workspace)
  local shell = os.getenv("SHELL") or "zsh"
  local args = " --class org.wezfurlong.wezterm." ..
      workspace .. " --workspace " .. workspace .. " --domain unix --attach"
  local command = "wezterm start" .. args .. shell
  Logger.i("Spawning wezterm with command: " .. command)
  io.popen("bash" .. [[ -l -i -c "]] .. command .. [["]])
  -- hs.execute(os.getenv("SHELL") .. [[ -l -i -c "]] .. command .. [["]])

  -- Wezterm may still be starting up, so we will keep looking for it and finally focus it when we do
  local count = 0
  hs.timer.waitUntil(
    function()
      count = count + 1
      if count >= 5 then
        Logger.w("Failed to find newly spawned Wezterm window after 20 tries.")
        return true
      end
      return wez.findWindow(workspace) ~= nil
    end,
    function() wez.toggleFocus(workspace, { force_show = true }) end,
    0.1)
end

---Return the first window whose name includes the workspace name
---TODO: This is a very fragile process since the window title may inadvertently contain the workspace name.
function wez.findWindow(workspace)
  hs.application.enableSpotlightForNameSearches(true)
  local terms = table.pack(hs.application.find("wezterm"))
  for _, term in ipairs(terms) do
    Logger.i("Searching for window " .. workspace .. " in wezterm: " .. term:name())
    local windows = table.pack(term:findWindow(workspace))
    if #windows > 0 then
      return windows[1]
    end
    Logger.i("No window " .. workspace .. " found in wezterm: " .. term:name())
  end
end

---Toggles the focus of the wezterm window named `workspace`
---@param workspace string The workspace name
---@param opts { force_show: boolean } Options:
---    force_show=nil: If true, always try to focus/center the window
---@return boolean isSuccess Whether the window was successfully focused
function wez.toggleFocus(workspace, opts)
  opts = opts or {}

  Logger.i("Toggling focus for wezterm window [" .. workspace .. "]")
  local win = wez.findWindow(workspace)
  if win == nil then
    Logger.e("Failed to find a wezterm window [" .. workspace .. "] to focus.")
    return false
  end

  -- hide/unhide
  if workspace == scratch then
    local app = win:application()
    -- Toggle scratch primary/minimised
    if win:isVisible() then
      if opts.force_show then
        win:centerOnScreen('0,0')
        win:focus()
      else
        app:hide()
      end
    elseif win:application():isHidden() then
      app:unhide()
      win:centerOnScreen('0,0')
      win:focus()
    end
  else
    win:focus()
  end
  return true
end

-- Setup keybinds
function wez.summon(workspace)
  hs.application.enableSpotlightForNameSearches(true)
  local terms = table.pack(hs.application.find("wezterm"))
  if #terms == 0 then
    Logger.e("No Wezterm found, spawning [" .. workspace .. "]")
    -- No Wezterm instances
    wez.spawn(workspace)
  else
    Logger.i("Found " .. #terms .. " Wezterm instances, toggling focus for [" .. workspace .. "]")
    local found = wez.toggleFocus(workspace)
    if not found then
      Logger.e("[" .. workspace .. "] not found, spawning")
      -- No windows to focus
      wez.spawn(workspace)
    end
  end
end

hs.hotkey.bind({ "alt" }, "`", function() wez.summon(scratch) end)
hs.hotkey.bind({ "alt" }, "1", function() wez.summon("work") end)
hs.hotkey.bind({ "alt" }, "2", function() wez.summon("pers") end)


claudeModel = dofile('./Spoons/claude-model-display.lua')
claudeModel.start()
