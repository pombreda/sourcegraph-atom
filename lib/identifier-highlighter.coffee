{Range, Point} = require 'atom'
child_process = require 'child_process'

util = require './util'

module.exports =
class IdentifierHighlighter
  constructor: (@editor, @statusView, @enabled) ->
    @markers = []

    @buffer = @editor?.getBuffer()
    return unless @buffer?

    # Clear highlights on modification to
    # prevent highlights from getting out of sync with actual text.
    modifiedSubscription = @buffer.onDidStopChanging =>
      @clearHighlights()

    # Re-highlight identifiers on save
    savedSubscription = @buffer.onDidSave =>
      @highlight()

    # When buffer is destroyed do cleanup.
    destroyedSubscription = @buffer.onDidDestroy ->
      modifiedSubscription?.dispose()
      savedSubscription?.dispose()
      destroyedSubscription?.dispose()

    console.log 'enabled', @enabled
    if @enabled
      # Delay this because buffer is still changing.
      setTimeout @highlight, 500

  # Check if we're edditing something `srclib` can parse.
  # FIXME: Remove this when srclib toolchains and atom integration
  #        are more stable.
  isValidEditor: ->
    # Supported languages:
    supportedScopes = [
      'source.python',
      'source.go',
      'source.java',
      # Beta:
      'source.haskell',
      'source.js',
      'source.scala',
      'text.html.php',
      'text.ruby',
    ]
    @editor?.getGrammar()?.scopeName in supportedScopes

  highlight: =>
    return if not @enabled or not @isValidEditor()

    @clearHighlights()

    if atom.config.get('sourcegraph-atom.highlightReferencesInFile')
      # Figure out project directory for editors file.
      filePath = @editor.getPath()
      [projectPath, relPath] = atom.project.relativizePath(filePath)

      command = "#{util.getSrcBin()} api list
                  --file \"#{filePath}\""

      @statusView.inprogress("Finding list of references in file: #{command}")
      child_process.exec(command, {
        maxBuffer: 200 * 1024 * 100,
        env: util.getEnv(),
        cwd: projectPath,
      }, (error, stdout, stderr) =>

        if error
          @statusView.error("#{command}: #{stderr}")
        else
          try
            output = JSON.parse(stdout)
          catch error
            @statusView.error("Parsing Error: #{stdout}")
            throw error
          if output?.Refs
            for ref in output.Refs
              start = util.byteToPosition(@editor, ref.Start)
              end = util.byteToPosition(@editor, ref.End)

              range = new Range(start, end)
              marker = @editor.markBufferRange(range)
              decoration = @editor.decorateMarker(marker,
               type: 'highlight',
               class: 'sourcegraph-identifier'
              )
              @markers.push(marker)
            @statusView.success('Highlighted all refs.')
          else
            @statusView.warn('No references in this file.')
      )

  # Enable highlighter.
  enable: ->
    @enabled = true
    @highlight()

  # Disable highighter.
  disable: ->
    @enabled = false
    @clearHighlights()

  # Remove markers from buffer.
  clearHighlights: ->
    marker.destroy() for marker in @markers
    @markers = []
