{Range, Point} = require 'atom'
child_process = require 'child_process'

util = require './util'

module.exports =
class IdentifierHighlighter
  # XXX: statusView is not really needed,
  #      could just emit event so it's more decoupled.
  constructor: (@editor, @statusView) ->
    @markers = []

    @buffer = @editor?.getBuffer()
    return unless @buffer?

    @filePath = @editor.getPath()

    # Clear highlights on modification to
    # prevent highlights from getting out of sync with actual text.
    modifiedsubscription = @buffer.onDidStopChanging =>
      @clearHighlights()

    # Re-highlight identifiers on save
    savedsubscription = @buffer.onDidSave =>
      @highlight()

    # When buffer is destroyed, delete this watch
    destroyedsubscription = @buffer.once 'destroyed', ->
      modifiedsubscription?.off()
      savedsubscription?.off()

    @highlight()

  highlight: ->
    @clearHighlights()

    if atom.config.get('sourcegraph-atom.highlightReferencesInFile')
      command = "#{util.getSrcBin()} api list
                  --file \"#{@filePath}\""

      @statusView.inprogress("Finding list of references in file: #{command}")
      child_process.exec(command, {
        maxBuffer: 200 * 1024 * 100,
        env: util.getEnv()
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
              console.log('edit', @editor)
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

  clearHighlights: ->
    for marker in @markers
      marker.destroy()
