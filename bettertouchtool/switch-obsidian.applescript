tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell

do shell script "echo '" & frontApp & "' > /tmp/previous_app.txt"

tell application "Obsidian" to activate
