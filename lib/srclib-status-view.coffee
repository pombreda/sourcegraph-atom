{View} = require 'atom'

module.exports =
class SrclibStatusView extends View
  @content: ->
    @div class: 'inline-block', =>
      @span class: ' build-success build-status', outlet: 'status', tabindex: -1, '', =>
        @img class: 'status-image'
        @text "srclib"

  attach: ->
    console.log("Attaching status view to status bar...")
    atom.workspaceView.statusBar.appendLeft(this)
    @setTooltip({
        title: "<h2>No source units were found.</h2>",
        delay: {
          show: 0
        }
    })

  serialize: ->
