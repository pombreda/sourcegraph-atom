{$, $$, SelectListView} = require 'atom'
_ = require 'underscore-plus'
openbrowser = require './openbrowser'

module.exports =
class SearchView extends SelectListView
  initialize: ->
    super
    @addClass('sg-search-view overlay from-top')
  getFilterKey: ->
    'eventDescription'

  toggle: ->
    if @hasParent()
      @cancel()
    else
      @attach()

  attach: ->
    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement
    else
      @eventElement = atom.workspaceView

    events = []
    for eventName, eventDescription of _.extend($(window).events(), @eventElement.events())
      events.push({eventName, eventDescription}) if eventDescription
    events = _.sortBy(events, 'eventDescription')
    @setItems(events)

    atom.workspaceView.append(this)
    @focusFilterEditor()

  populateList: ->
    query = @getFilterQuery()


    results = []
    apicall = 'https://sourcegraph.com/api/search?Defs=true&People=true&Repositories=true&q=' + query
    console.log(apicall)

    me = this
    $.ajax
      url: apicall
      success: (data) ->
        console.log(data)
        if data.Repositories
          for repo in data.Repositories
            results.push({
              text : "(Repo)" + repo.URI,
              url : 'https://sourcegraph.com/' + repo.URI
            })

        # TODO: Show Defs in seach bar
        ###
        for def in data.Defs
          results.push({
            text: def.Name
          })###

        # TODO: Show Refs in bar

        results.push({
          text: "See More Results on Sourcegraph.com",
          url : "https://sourcegraph.com/search?q=" + query
        })

        me.list.empty()
        if results.length
          for item in results
            itemView = $(me.viewForItem(item))
            itemView.data('select-list-item', item)
            me.list.append(itemView)
          me.selectItemView(me.list.find('li:first'))
        else
          me.setError(me.getEmptyMessage(me.items.length, results.length))


  viewForItem: (result) ->
    $$ ->
      @li class: 'event', =>
        @span result.text, title: result.text

  confirmed: (result) ->
    @cancel()
    if result.url
      openbrowser(result.url)
