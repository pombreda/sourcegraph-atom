{View} = require 'atom'

module.exports =
class SrclibStatusView extends View
  @content: ->
    @div class: 'inline-block', =>
      @span class: 'build-status', outlet: 'status', tabindex: -1, '', =>
        @img class: 'status-image'
        @text "srclib"

  attach: ->
    console.log("Attaching status view to status bar...")
    atom.workspaceView.statusBar.appendLeft(this)

  message: (html) ->
    @setTooltip({
        title: html,
        delay: {
          show: 0
        }
    })

  serialize: ->

  reset: ->
    @status.removeClass("build-success").removeClass("build-fail").removeClass("build-inprogress")

  inprogress: (html = "") ->
    @reset()
    @status.addClass("build-inprogress")
    @message(html)

  fail: (html = "") ->
    @reset()
    @status.addClass("build-fail")
    @message(html)

  success: (html = "") ->
    @reset()
    @status.addClass("build-success")
    @message(html)
