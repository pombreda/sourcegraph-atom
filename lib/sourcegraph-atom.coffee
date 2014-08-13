ConditionalContextMenu = require './conditional-contextmenu'
SrclibStatusView = require('./srclib-status-view')
{EditorView, $} = require 'atom'

path = require 'path'
child_process = require 'child_process'
util = require 'util'

repeatString = (str, n) -> new Array( n + 1 ).join( str );

module.exports =
  activate: (state) ->
    statusView = new SrclibStatusView(state.viewState)
    atom.packages.once 'activated', ->
      statusView.attach()

      atom.workspaceView.eachEditorView (editorView) ->
        editor = editorView.getEditor()
        filePath = editor.getPath()
        command = util.format('src api list --file "%s"', filePath)

        overlay = editorView.overlayer.prepend("<div class='sourcegraph-overlay'></div>").find(".sourcegraph-overlay")
        console.log(overlay)

        child_process.exec(command, {
            maxBuffer: 200*1024*100
          }, (error, stdout, stderr) ->

          if error
            console.log(error)
          else
            for ref in JSON.parse(stdout)
              # TODO: Only works for ASCII
              start = editorView.pixelPositionForBufferPosition(editor.buffer.positionForCharacterIndex(ref.Start))
              end = editorView.pixelPositionForBufferPosition(editor.buffer.positionForCharacterIndex(ref.End))
              #console.log(start.top)

              identifier = $("<div class='identifier'></div>").appendTo(overlay)
              identifier.css({
                "top" : start.top,
                "left" : start.left,
                "width" : end.left - start.left
              });
              identifier.text(
                repeatString(" ", ref.End - ref.Start)
              );

            overlay.on 'mouseenter', ->
              console.log($this)
        )

    atom.workspaceView.command "sourcegraph-atom:jump-to-definition", => @jumpToDefinition true

    ConditionalContextMenu.item {
      label: 'Jump To Definition'
      command: 'sourcegraph-atom:jump-to-definition',
    }, => return true


  jumpToDefinition: ->
