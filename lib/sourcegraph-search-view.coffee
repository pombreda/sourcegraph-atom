{$, $$, SelectListView} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
openbrowser = require './openbrowser'
util = require 'util'

module.exports =
class SearchView extends SelectListView
  initialize: ->
    super
    @addClass('sg-search-view')

    # Throttle search requests
    @search_throttled = _.throttle(@search, 100)

  search: (query) ->
    me = this
    results = []
    apicall = 'https://sourcegraph.com/api/search?Defs=true&People=true&Repositories=true&q=' + query
    console.log(apicall)

    $.ajax
      url: apicall
      success: (data) ->
        console.log(data)

        # Show repositories
        if data.Repositories
          for repo in data.Repositories
            results.push({
              text : "(Repo) " + repo.URI,
              url : 'https://sourcegraph.com/' + repo.URI
            })

        # Shows Defs in seach bar
        if data.Defs
          for def in data.Defs
            results.push({
              text: "(Def) " + def.Name + " - " + def.Repo,
              url : util.format("https://www.sourcegraph.com/%s/.%s/%s/.def/%s", def.Repo, def.UnitType, def.Unit, def.Path)
            })

        # Show People in bar
        if data.People
          for person in data.People
            results.push({
                text: "(Person) " + person.Name,
                url : util.format("https://www.sourcegraph.com/%s", person.Login)
              })

        # Ability to see more results on sourcegraph.com
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

  getFilterKey: ->
    'eventDescription'

  cancelled: ->
    @hide()

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @show()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()

    events = []
    for eventName, eventDescription of _.extend($(window).events(), @eventElement.events())
      events.push({eventName, eventDescription}) if eventDescription
    events = _.sortBy(events, 'eventDescription')
    @setItems(events)

    @focusFilterEditor()

  populateList: ->
    query = @getFilterQuery()
    @search_throttled(query)

  viewForItem: (result) ->
    $$ ->
      @li class: 'event', =>
        @span result.text, title: result.text

  confirmed: (result) ->
    @cancel()
    if result.url
      openbrowser(result.url)

  hide: ->
    @panel?.hide()
