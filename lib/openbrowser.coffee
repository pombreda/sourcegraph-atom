exec = require("child_process").exec
os = require("os")

module.exports = (url) ->
  console.log("Opening " + url + "...")

  switch os.platform()
    when "linux"
      exec('xdg-open "' + url + '"')
    when "darwin"
      # TODO: Confirm that this works on Mac
      exec('open "' + url + '"')
    when "win32"
      # TODO: Confirm that this works on Windows
      exec('start "' + url + '"')
    else
      console.log("Unable to open web browser - unkown platform.")
