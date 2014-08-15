{View} = require 'atom'


current_status = {
  content: ""
  type: ""
}

class StatusInfo extends View
  @content: ->
    @div tabindex: -1, class: 'srclib-status-info overlay from-bottom from-left native-key-bindings', =>
      @h1 current_status.type
      @raw current_status.content

  initialize: ->
    atom.workspaceView.prepend(this)

    @subscribe this, 'focusout', =>
      # during the focusout event body is the active element. Use nextTick to determine what the actual active element will be
      process.nextTick =>
        @detach() unless @is(':focus') or @find(':focus').length > 0

    @subscribe atom.workspaceView, 'core:cancel', => @detach()

    @focus()

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

  initialize: ->
    @on 'click', ->
      new StatusInfo()

  message: (type, content) ->
    current_status = {
      type,
      content
    }

  serialize: ->

  reset: ->
    @status.removeClass("build-success").removeClass("build-fail").removeClass("build-inprogress")

  inprogress: (html = "") ->
    @reset()
    @status.addClass("build-inprogress")
    @message("Running Command", html)

  fail: (html = "") ->
    @reset()
    @status.addClass("build-fail")
    @message("Command Failed", html)

  success: (html = "") ->
    @reset()
    @status.addClass("build-success")
    @message("Command Succeded", html)
