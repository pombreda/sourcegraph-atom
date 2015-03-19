exec = require('child_process').exec
os = require('os')

module.exports =
  # Get `src` binary location.
  getSrcBin: ->
    location = atom.config.get('sourcegraph-atom.srcExecutablePath').trim()
    return if location.length then location else 'src'

  # Get process ENV. Also sets GOPATH and GOROOT and adjusts GOPATH.
  getEnv: ->
    goPath = atom.config.get('sourcegraph-atom.goPath').trim()
    if goPath.length
      process.env.GOPATH = goPath
    goRoot = atom.config.get('sourcegraph-atom.goRoot').trim()
    if goRoot.length
      process.env.GOROOT = goRoot
    path = atom.config.get('sourcegraph-atom.path').trim()
    for p in path.split(':')
      if p not in process.env.PATH.split(':')
        process.env.PATH += ':' + p
    return process.env

  # Open browser.
  openBrowser: (url) ->
    console.log("Opening #{url} ...")
    switch os.platform()
      when 'linux'
        exec("xdg-open \"#{url}\"")
      when 'darwin'
        # TODO: Confirm that this works on Mac
        exec("open \"#{url}\"")
      when 'win32'
        # TODO: Confirm that this works on Windows
        # TODO: What about Windows 64bit?
        exec("start \"#{url}\"")
      else
        console.log('Unable to open web browser - unkown platform.')

  # Convert byte position to editor position.
  byteToPosition: (editor, byte) ->
    # FIXME: Only works for ASCII
    editor.buffer.positionForCharacterIndex(byte)

  # Convert editor position to byte position.
  positionToByte: (editor, point) ->
    # FIXME: Only works for ASCII
    editor.buffer.characterIndexForPosition(point)
