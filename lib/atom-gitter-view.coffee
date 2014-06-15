{View} = require 'atom'

module.exports =
class AtomGitterView extends View
  @content: ->
    @div class: 'atom-gitter overlay from-top panel', =>
      @div
        class: 'panel-heading'
        'Send a message with Gitter'
      @div class: 'panel-body padded', =>
        @textarea
          type: 'text'
          class: 'form-control native-key-bindings'
          placeholder: 'Enter your message to post on Gitter'
          value: ''
          outlet: 'inputMessage'

        @div class: 'block', =>
          @button
            class: 'btn btn-warning'
            click: 'toggle'
            'Close'
          @button
            class: 'btn btn-primary pull-right'
            click: 'sendMessage'
            'Send message'


  initialize: (serializeState) ->
    atom.workspaceView.command "atom-gitter:toggle", => @toggle()
    @gitter = serializeState

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    # console.log "AtomGitterView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)

  sendMessage: ->
    # Get input message
    msg = @inputMessage.val()
    # Send message
    if @gitter.currentRoom and msg
      @gitter.currentRoom.send msg
    # Clear inputMessage
    @inputMessage.val ''
