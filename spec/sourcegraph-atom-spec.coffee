SourcegraphAtom = require '../lib/sourcegraph-atom'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe 'SourcegraphAtom', ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('sourcegraph-atom')

  describe 'when the sourcegraph-atom:toggle event is triggered', ->
    it 'attaches and then detaches the view', ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.sourcegraph-atom')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'sourcegraph-atom:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        testAtomElement = workspaceElement.querySelector('.sourcegraph-atom')
        expect(testAtomElement).toExist()

        testAtomPanel = atom.workspace.panelForItem(testAtomElement)
        expect(testAtomPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'sourcegraph-atom:toggle'
        expect(testAtomPanel.isVisible()).toBe false

    it 'hides and shows the view', ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.sourcegraph-atom')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'sourcegraph-atom:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        testAtomElement = workspaceElement.querySelector('.sourcegraph-atom')
        expect(testAtomElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'sourcegraph-atom:toggle'
        expect(testAtomElement).not.toBeVisible()
