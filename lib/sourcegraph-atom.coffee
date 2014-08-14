ConditionalContextMenu = require './conditional-contextmenu'

{Editor, EditorView, $, Range, Point} = require 'atom'


path = require 'path'
child_process = require 'child_process'
util = require 'util'
openbrowser = require './openbrowser'



repeatString = (str, n) -> new Array( n + 1 ).join( str );

ExamplesView = require './sourcegraph-examples-view'
examplesView = null

SrclibStatusView = require('./srclib-status-view')
statusView = null

SearchView = require('./sourcegraph-search-view')
searchView = null

byteToPosition = (editor, byte) ->
  # FIXME: Only works for ASCII
  editor.buffer.positionForCharacterIndex(byte)

positionToByte = (editor, point) ->
  # FIXME: Only works for ASCII
  editor.buffer.characterIndexForPosition(point)

module.exports =
  activate: (state) ->
    statusView = new SrclibStatusView(state.viewState)
    searchView = new SearchView(state.viewState)

    atom.packages.once 'activated', ->
      statusView.attach()

      atom.workspaceView.eachEditorView (editorView) ->
        editor = editorView.getEditor()
        filePath = editor.getPath()
        command = util.format('src api list --file "%s"', filePath)
        console.log(command)

        statusView.inprogress(command)
        child_process.exec(command, {
            maxBuffer: 200*1024*100
          }, (error, stdout, stderr) ->

          if error
            console.log(error)
            statusView.fail(error)
          else
            refs = JSON.parse(stdout)
            if refs
              for ref in refs
                start = byteToPosition(editor, ref.Start)
                end = byteToPosition(editor, ref.End)

                range = new Range(start, end)
                marker = editor.markBufferRange(range)
                decoration = editor.decorateMarker(marker, {type : 'highlight', class : "identifier"})
              #TODO: Reload highlights on file save
            else
              console.log("No references in this file.")

            statusView.success()
        )

    # TODO: Add keyboard shortcuts
    atom.workspaceView.command "sourcegraph-atom:jump-to-definition", => @jumpToDefinition true
    atom.workspaceView.command "sourcegraph-atom:docs-examples", => @docsExamples true

    atom.workspaceView.command "sourcegraph-atom:search-on-sourcegraph", => @searchOnSourcegraph true

    atom.workspace.registerOpener (uri) ->
      console.log(uri)
      if uri is 'sourcegraph-atom://docs-examples'
        return new ExamplesView()
      else
        return null

    ###ConditionalContextMenu.item {
      label: 'Jump To Definition'
      command: 'sourcegraph-atom:jump-to-definition',
    }, => return true

    ConditionalContextMenu.item {
      label: 'See Documentation and Examples'
      command: 'sourcegraph-atom:docs-examples',
    }, => return true###


  jumpToDefinition: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()

    offset = positionToByte(editor, editor.getCursorBufferPosition())
    command = util.format('src api describe --file="%s" --start-byte=%d --no-examples', filePath, offset)
    console.log(command)

    statusView.inprogress(command)
    child_process.exec(command, {
        maxBuffer: 200*1024*100
      }, (error, stdout, stderr) ->

      if error
        console.log(error)
        statusView.fail(error)
      else

        result = JSON.parse(stdout)

        def = result.Def
        if not def
          statusView.success("Not a valid reference.")
        else
          statusView.success()
          if not def.Repo
            #FIXME: Only works when atom project path matches
            atom.workspace.open( path.join(atom.project.getPath(), def.File)).then( (editor) ->
              offset = byteToPosition(editor, def.DefStart)

              editor.setCursorBufferPosition(offset)
              editor.scrollToCursorPosition()
            )
          else
            # TODO: Resolve to local file, for now, just opens sourcegraph.com
            url = util.format("http://www.sourcegraph.com/%s/.%s/%s/.def/%s", def.Repo, def.UnitType, def.Unit, def.Path)
            openbrowser(url)

    )

  docsExamples: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()
    offset = positionToByte(editor, editor.getCursorBufferPosition())
    command = util.format('src api describe --file="%s" --start-byte=%d', filePath, offset)
    console.log(command)
    statusView.inprogress(command)

    child_process.exec(command, {
        maxBuffer: 200*1024*100
      }, (error, stdout, stderr) ->

      if error
        console.log(error)
        statusView.fail(error)
      else
        previousActivePane = atom.workspace.getActivePane()
        atom.workspace.open('sourcegraph-atom://docs-examples', split: 'right', searchAllPanes: true).done (examplesView) ->
          examplesView.display(JSON.parse(stdout))
          previousActivePane.activate()
          statusView.success("Not a valid reference.")
    )

  searchOnSourcegraph: ->
    searchView.toggle()
