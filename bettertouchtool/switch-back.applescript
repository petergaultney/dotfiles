try
  set previousApp to do shell script "cat /tmp/previous_app.txt"
  tell application previousApp to activate
end try
