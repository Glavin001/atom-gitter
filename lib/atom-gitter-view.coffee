{View} = require 'atom'

module.exports =
class AtomGitterView extends View
  @content: ->
    @div class: 'atom-gitter overlay from-top', =>
      @div "The AtomGitter package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "atom-gitter:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "AtomGitterView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
