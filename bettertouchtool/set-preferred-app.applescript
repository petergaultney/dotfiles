-- This captures the current app as your "preferred" app
tell application "System Events"
    set currentApp to name of first application process whose frontmost is true
    set currentBundleID to bundle identifier of first application process whose frontmost is true
end tell

do shell script "echo '" & currentApp & "' > /tmp/preferred_app.txt"
do shell script "echo '" & currentBundleID & "' > /tmp/preferred_bundle.txt"

-- Optional: Show confirmation
display notification "Set preferred app to: " & currentApp
