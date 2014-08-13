{$, $$$, ScrollView} = require 'atom'

module.exports =
class ExamplesView extends ScrollView
  @content: ->
    @div class: 'examples-page native-key-bindings', tabindex: -1
