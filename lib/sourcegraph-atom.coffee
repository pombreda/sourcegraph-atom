ConditionalContextMenu = require './conditional-contextmenu'
SrclibStatusView = require('./srclib-status-view')
{Editor, EditorView, $, Range, Point} = require 'atom'

path = require 'path'
child_process = require 'child_process'
util = require 'util'

ExamplesView = require './sourcegraph-examples-view'

repeatString = (str, n) -> new Array( n + 1 ).join( str );

examplesView = null

byteToPosition = (editor, byte) ->
  # TODO: Only works for ASCII
  editor.buffer.positionForCharacterIndex(byte)

positionToByte = (editor, point) ->
  # TODO: Only works for ASCII
  editor.buffer.characterIndexForPosition(point)

module.exports =
  activate: (state) ->
    statusView = new SrclibStatusView(state.viewState)


    atom.packages.once 'activated', ->
      statusView.attach()

      atom.workspaceView.eachEditorView (editorView) ->
        editor = editorView.getEditor()
        filePath = editor.getPath()
        command = util.format('src api list --file "%s"', filePath)
        console.log(command)

        child_process.exec(command, {
            maxBuffer: 200*1024*100
          }, (error, stdout, stderr) ->

          if error
            console.log(error)
          else
            for ref in JSON.parse(stdout)
              # TODO: Only works for ASCII
              start = editor.buffer.positionForCharacterIndex(ref.Start)
              end = editor.buffer.positionForCharacterIndex(ref.End)


              range = new Range(start, end)
              marker = editor.markBufferRange(range)
              decoration = editor.decorateMarker(marker, {type : 'highlight', class : "identifier"})

            #overlay.on 'mouseenter', ->
              #console.log($this)
        )

    atom.workspaceView.command "sourcegraph-atom:jump-to-definition", => @jumpToDefinition true
    atom.workspaceView.command "sourcegraph-atom:docs-examples", => @docsExamples true

    ConditionalContextMenu.item {
      label: 'Jump To Definition'
      command: 'sourcegraph-atom:jump-to-definition',
    }, => return true

    ConditionalContextMenu.item {
      label: 'See Documentation and Examples'
      command: 'sourcegraph-atom:docs-examples',
    }, => return true


  jumpToDefinition: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()
    # TODO: Only works for ASCII
    offset = positionToByte(editor, editor.getCursorBufferPosition())
    command = util.format('src api describe --file="%s" --start-byte=%d', filePath, offset)
    console.log(command)

    child_process.exec(command, {
        maxBuffer: 200*1024*100
      }, (error, stdout, stderr) ->

      if error
        console.log(error)
      else
        result = JSON.parse(stdout)

        def = result.Def
        if def.Repo
          pass
        else
          #TODO: Only works when atom project path matches
          atom.workspace.open( path.join(atom.project.getPath(), def.File)).then( (editor) ->
            offset = byteToPosition(editor, def.DefStart)

            editor.setCursorBufferPosition(offset)
            editor.scrollToCursorPosition()
          )
    )

  docsExamples: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()
    # TODO: Only works for ASCII
    offset = editor.buffer.characterIndexForPosition(editor.getCursorBufferPosition())
    command = util.format('src api describe --file="%s" --start-byte=%d --examples', filePath, offset)
    console.log(command)

    child_process.exec(command, {
        maxBuffer: 200*1024*100
      }, (error, stdout, stderr) ->

      if error
        console.log(error)
      else
        console.log(stdout)
    )
