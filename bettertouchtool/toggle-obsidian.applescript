tell application "System Events"
    set currentApp to name of first application process whose frontmost is true
    set currentBundleID to bundle identifier of first application process whose frontmost is true
end tell

-- Determine target app (preferred or fallback to Obsidian)
try
    set preferredApp to do shell script "cat /tmp/preferred_app.txt 2>/dev/null"
    set preferredBundleID to do shell script "cat /tmp/preferred_bundle.txt 2>/dev/null"
    if preferredApp is "" then error
    set targetApp to preferredApp
    set targetBundleID to preferredBundleID
on error
    -- Fallback to Obsidian
    set targetApp to "Obsidian"
    set targetBundleID to "md.obsidian"
end try

if currentApp is not targetApp then
    -- Store current app and switch to target
    do shell script "echo '" & currentApp & "' > /tmp/previous_app.txt"
    do shell script "echo '" & currentBundleID & "' > /tmp/previous_bundle.txt"
    tell application id targetBundleID to activate
else
    -- We're in target app, switch back to previous app
    set previousBundleID to do shell script "cat /tmp/previous_bundle.txt 2>/dev/null"
    tell application id previousBundleID to activate
end if
