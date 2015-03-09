{ScrollView} = require 'atom-space-pen-views'

_ = require 'underscore-plus'

mustache = require 'mustache'
examplesTemplate = """
<h1>{{Def.Name}}</h1>
{{{Def.DocHTML}}}

<h2>Details</h2>
<table>
  <tr><td>Repository</td><td>{{Def.Repo}}</td></tr>
  <tr><td>File</td><td>{{Def.File}}</td></tr>
  {{#Def.DataPairs}}
    <tr>{{#.}}<td>{{ stringify }}</td>{{/.}}</tr>
  {{/Def.DataPairs}}
</table>

<h2>Examples on Sourcegraph</h2>
{{#Examples}}
  <h3>{{Repo}} @ {{File}}:{{StartLine}}-{{EndLine}}</h3>
  <pre><code>{{{SrcHTML}}}</code></pre>
  <hr>
{{/Examples}}
"""

module.exports =
class ExamplesView extends ScrollView
  # TODO: Add serialization

  @content: ->
    @div class: 'examples-page native-key-bindings', tabindex: -1

  display: (data) ->
    data.Def.DataPairs = _.pairs(data.Def.Data)
    data.stringify = () ->
      if this instanceof String
        return this
      else
        JSON.stringify(this)

    console.log(data)
    @html(mustache.render(examplesTemplate, data))

  getTitle: ->
    return "Sourcegraph Examples"

  getUri: ->
    return 'sourcegraph-atom://docs-examples'

  getIconName: ->
    "markdown"

  getPath: ->
    return 'sourcegraph-atom://docs-examples'
