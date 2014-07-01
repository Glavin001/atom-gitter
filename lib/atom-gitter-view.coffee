{View} = require 'atom'

module.exports =
class AtomGitterView extends View
  @content: ->
    @div class: 'gitter overlay from-top panel', =>
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
    @gitter = serializeState
    atom.workspaceView.command "gitter:toggle", => @toggle()
    atom.workspaceView.command "gitter:toggle-compose-message", => @toggle()
    atom.workspaceView.command "gitter:send-selected-code", => @sendSelectedCode()
    atom.workspaceView.command "gitter:send-message", => @sendMessage()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
      @inputMessage.focus() # Focus on message input

  sendSelectedCode: ->
    editor = atom.workspace.getActiveEditor()
    # Get selected code
    text = editor.getSelectedText()
    # Check if there is a message to send
    if text
      # Get code language from grammar
      grammar = editor.getGrammar()
      name = grammar.name
      # Create message
      message = '```'+name+'\n'+text+'\n```'
      # Send message
      if @gitter.currentRoom and text
        @gitter.currentRoom.send message

  sendMessage: ->
    # Get input message
    msg = @inputMessage.val()
    # Send message
    if @gitter.currentRoom and msg
      @gitter.currentRoom.send msg
    # Clear inputMessage
    @inputMessage.val ''
