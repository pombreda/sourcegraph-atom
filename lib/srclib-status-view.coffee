{Emitter} = require 'atom'
{View} = require 'atom-space-pen-views'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =
class SrclibStatusView extends View
  @content: ->
    @div class: 'inline-block', =>
      @span class: 'status', outlet: 'status', tabindex: -1, '', =>
        @div class: 'status-icon'
        @span 'srclib', class: 'status-text'

  initialize: ->
    @emitter = new Emitter

    @messages = new MessagePanelView
      title: '<img src="atom://sourcegraph-atom/assets/icon.svg">\
              </img> srclib status'
      rawTitle: true
    @on 'click', '.status-text', =>
      @messages.attach()
    @on 'click', '.status-icon', =>
      @emitter.emit 'toggle'
      return false

  onToggle: (callback) ->
    @emitter.on 'toggle', callback

  reset: ->
    @status
      .removeClass('state-disabled')
      .removeClass('build-success')
      .removeClass('build-warn')
      .removeClass('build-fail')
      .removeClass('build-inprogress')

  # Make the icon look disabled, remove message pane.
  disable: ->
    @reset()
    @status.addClass('state-disabled')
    @messages.close()

  # Re-enable message pane.
  enable: ->
    @reset()
    @messages.attach()

  inprogress: (html) ->
    @reset()
    @status.addClass('build-inprogress')

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.log(html)

    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-info'
      }))

  error: (html) ->
    @reset()
    @status.addClass('build-fail')

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
    @status.addClass('build-warn')

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
    @status.addClass('build-success')

    if html
      @messages.add(new PlainMessageView({
        message: html,
        className: 'text-success'
      }))

    if atom.config.get('sourcegraph-atom.logStatusToConsole')
      console.log(html)
