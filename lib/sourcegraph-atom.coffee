{Editor, EditorView, $, Range, Point} = require 'atom'


path = require 'path'
child_process = require 'child_process'
util = require 'util'
openbrowser = require './openbrowser'


ExamplesView = require './sourcegraph-examples-view'
examplesView = null

SrclibStatusView = require('./srclib-status-view')
statusView = null

SearchView = require('./sourcegraph-search-view')
searchView = null

class IdentifierHighlighting
  constructor: (@editorView) ->
    @decorations = []

    @buffer = @editorView?.getEditor()?.getBuffer()
    return unless @buffer?

    @editor = @editorView.getEditor()
    @filePath = @editor.getPath()

    # Clear highlights on modification (to prevent highlights from getting out of sync with actual text)
    modifiedsubscription = @buffer.on 'contents-modified', =>
      @clearHighlights()

    # Re-highlight identifiers on save
    savedsubscription = @buffer.on 'saved', =>
      @highlight()

    # When buffer is destroyed, delete this watch
    destroyedsubscription = @buffer.once 'destroyed', =>
      modifiedsubscription?.off()
      savedsubscription?.off()

    @highlight()

  highlight: ->
    @clearHighlights()

    if atom.config.get('sourcegraph-atom.highlightReferencesInFile')
      command = util.format('%s api list --file "%s"', src(), @filePath)

      highlighter = this

      statusView.inprogress("Finding list of references in file: " + command)
      child_process.exec(command, {
          maxBuffer: 200*1024*100,
          env: getEnv()
        }, (error, stdout, stderr) ->

        if error
          statusView.error(command + ": " + stderr)
        else
          try
            refs = JSON.parse(stdout)
          catch error
            statusView.error("Parsing Error: " + stdout)
            throw error
          if refs
            for ref in refs
              start = byteToPosition(highlighter.editor, ref.Start)
              end = byteToPosition(highlighter.editor, ref.End)

              range = new Range(start, end)
              marker = highlighter.editor.markBufferRange(range)
              decoration = highlighter.editor.decorateMarker(marker, {type : 'highlight', class : "identifier"})
              highlighter.decorations.push(decoration)
            statusView.success("Highlighted all refs.")
          else
            statusView.warn("No references in this file.")
      )

  clearHighlights: ->
    for decoration in @decorations
      decoration.destroy()

repeatString = (str, n) -> new Array( n + 1 ).join( str );

byteToPosition = (editor, byte) ->
  # FIXME: Only works for ASCII
  editor.buffer.positionForCharacterIndex(byte)

positionToByte = (editor, point) ->
  # FIXME: Only works for ASCII
  editor.buffer.characterIndexForPosition(point)

src = () ->
  location = atom.config.get('sourcegraph-atom.srcExecutablePath').trim()
  if location.length
    return location
  else
    return "src"

getEnv = () ->
  goPath = atom.config.get('sourcegraph-atom.goPath').trim()
  if goPath.length
    process.env.GOPATH = goPath
  goRoot = atom.config.get('sourcegraph-atom.goRoot').trim()
  if goRoot.length
    process.env.GOROOT = goRoot
  path = atom.config.get('sourcegraph-atom.path').trim()
  for p in path.split(":")
    if p not in process.env.PATH.split(":")
      process.env.PATH += ':' + p
  return process.env

module.exports =
  config:
    goPath:
      type: 'string'
      default: ''
      description: 'Path to your $GOPATH. Uses $GOPATH from env if not specified.'
    goRoot:
      type: 'string'
      default: ''
      description: 'Path to your $GOROOT. Uses $GOROOT from env if not specified. Most people won\'t need to set this, even if their $GOROOT is unset. See http://dave.cheney.net/2013/06/14/you-dont-need-to-set-goroot-really'
    path:
      type: 'string'
      default: ''
      description: 'Add items to your PATH, separated by \':\''
    srcExecutablePath:
      type: 'string'
      default: ''
      description: 'Path to src executable. By default, this assumes it is already in the path'
    highlightReferencesInFile:
      type: 'boolean'
      default: true
    openMessagePanelOnError:
      type: 'boolean'
      default: true
    logStatusToConsole:
      type: 'boolean'
      default: false

  activate: (state) ->
    # Ensure that Atom's path has common src locations
    if '/usr/local/bin' not in process.env.PATH.split(":")
      process.env.PATH += ':/usr/local/bin'

    statusView = new SrclibStatusView(state.viewState)
    searchView = new SearchView(state.viewState)

    atom.packages.once 'activated', ->
      # Attach status view
      statusView.attach()

      atom.workspaceView.eachEditorView (editorView) ->
        new IdentifierHighlighting(editorView)

    atom.workspaceView.command "sourcegraph-atom:jump-to-definition", => @jumpToDefinition true
    atom.workspaceView.command "sourcegraph-atom:docs-examples", => @docsExamples true

    atom.workspaceView.command "sourcegraph-atom:search-on-sourcegraph", => @searchOnSourcegraph true

    atom.workspace.registerOpener (uri) ->
      console.log(uri)
      if uri is 'sourcegraph-atom://docs-examples'
        return new ExamplesView()
      else
        return null

  jumpToDefinition: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()

    offset = positionToByte(editor, editor.getCursorBufferPosition())
    command = util.format('%s api describe --file="%s" --start-byte=%d --no-examples', src(), filePath, offset)

    statusView.inprogress("Jump to Definition: " + command)
    child_process.exec(command, {
        maxBuffer: 200*1024*100,
        env: getEnv()
      }, (error, stdout, stderr) ->

      if error
        statusView.error(command + ": " + stderr)
      else

        result = JSON.parse(stdout)

        def = result.Def
        if not def
          statusView.warn("No reference found under cursor.")
        else
          if not def.Repo
            statusView.success("Successfully resolved to local definition.")
            #FIXME: Only works when atom project path matches
            atom.workspace.open( def.File ).then( (editor) ->
              offset = byteToPosition(editor, def.DefStart)

              editor.setCursorBufferPosition(offset)
              editor.scrollToCursorPosition()
            )
          else
            statusView.success("Successfully resolved to remote definition.")
            # TODO: Resolve to local file, for now, just opens sourcegraph.com
            url = util.format("http://www.sourcegraph.com/%s/.%s/%s/.def/%s", def.Repo, def.UnitType, def.Unit, def.Path)
            openbrowser(url)

    )

  docsExamples: ->
    editor = atom.workspace.getActiveEditor()
    filePath = editor.getPath()
    offset = positionToByte(editor, editor.getCursorBufferPosition())
    command = util.format('%s api describe --file="%s" --start-byte=%d',src(), filePath, offset)
    statusView.inprogress("Documentation and Examples:" + command)

    child_process.exec(command, {
        maxBuffer: 200*1024*100,
        env: getEnv()
      }, (error, stdout, stderr) ->
      if error
        statusView.error(command + ": " + stderr)
      else
        result = JSON.parse(stdout)
        if not result.Def
          statusView.warn("No reference found under cursor.")
        else
          previousActivePane = atom.workspace.getActivePane()
          atom.workspace.open('sourcegraph-atom://docs-examples', split: 'right', searchAllPanes: true).done (examplesView) ->
            examplesView.display(result)
            previousActivePane.activate()
            statusView.success("Opened docs panel")
    )

  searchOnSourcegraph: ->
    searchView.toggle()
