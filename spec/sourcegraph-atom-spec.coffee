{WorkspaceView} = require 'atom'
SourcegraphAtom = require '../lib/sourcegraph-atom'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "SourcegraphAtom", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('sourcegraph-atom')

  describe "when the sourcegraph-atom:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.sourcegraph-atom')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'sourcegraph-atom:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.sourcegraph-atom')).toExist()
        atom.workspaceView.trigger 'sourcegraph-atom:toggle'
        expect(atom.workspaceView.find('.sourcegraph-atom')).not.toExist()
