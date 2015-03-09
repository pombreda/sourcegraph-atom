{View} = require 'atom-space-pen-views'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =
class SrclibStatusView extends View
  @content: ->
    @div class: 'inline-block', =>
      @span class: 'build-status', outlet: 'status', tabindex: -1, '', =>
        @img class: 'status-image'
        @text "srclib"

  initialize: ->
    @messages = new MessagePanelView title: '<img src="atom://sourcegraph-atom/assets/nobuild.svg"></img> srclib status', rawTitle: true
    @on 'click', =>
      @messages.attach()

  serialize: ->

  reset: ->
    @status.removeClass("build-success").removeClass("build-warn").removeClass("build-fail").removeClass("build-inprogress")

  inprogress: (html) ->
    @reset()
    @status.addClass("build-inprogress")

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.log(html)

    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-info'
      }))

  error: (html) ->
    @reset()
    @status.addClass("build-fail")

    if atom.config.get('sourcegraph-atom.openMessagePanelOnError')
      @messages.attach()

    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-error'
      }))

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.error(html)

  warn: (html) ->
    @reset()
    @status.addClass("build-warn")



    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-warning'
      }))

    if atom.config.get('sourcegraph-atom.openMessagePanelOnError')
      @messages.attach()

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.warn(html)

  success: (html) ->
    @reset()
    @status.addClass("build-success")

    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-success'
      }))

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.log(html)
