{$, $$, SelectListView} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
openbrowser = require './openbrowser'

module.exports =
class SearchView extends SelectListView
  initialize: ->
    super
    @addClass('sg-search-view')

    # Throttle search requests
    @search_throttled = _.throttle(@search, 1000)

  search: (query) ->
    me = this
    results = []
    apicall = "https://sourcegraph.com/api/\
               search?Defs=true&People=true&Repos=true&q=#{query}"
    console.log(apicall)

    # If old request is still processing, abort it.
    @xhr?.abort()

    @xhr = $.ajax
      url: apicall
      success: (data) =>
        console.log(data)

        # Show repositories
        if data.Repos
          for repo in data.Repos
            results.push({
              text: "(Repo) #{repo.URI}",
              url: "https://sourcegraph.com/#{repo.URI}"
            })

        # Shows Defs in seach bar
        if data.Defs
          for def in data.Defs
            results.push({
              text: "(Def) #{def.Name} - #{def.Repo}",
              url: "https://www.sourcegraph.com/\
                     #{def.Repo}/#{def.UnitType}/#{def.Unit}/.def/#{def.Path}"
            })

        # Show People in bar
        if data.People
          for person in data.People
            results.push({
              text: "(Person) #{person.Name}",
              url: "https://www.sourcegraph.com/#{person.Login}"
            })

        # Ability to see more results on sourcegraph.com
        results.push({
          text: 'See More Results on Sourcegraph.com',
          url: "https://sourcegraph.com/search?q=#{query}"
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
        @xhr = null

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
