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
    atom.workspaceView.command "atom-gitter:send-selected-code", => @sendSelectedCode()
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

  sendSelectedCode: ->
    editor = atom.workspace.getActiveEditor()
    # Get selected code
    text = editor.getSelectedText()
    console.log editor.getSelectedText, editor.getSelection()
    console.log text

    selections = editor.getSelections()
    for s in selections
      console.log s.getText?()
      console.log s

    if text
      # Get code language from grammar
      name = editor.getGrammar().name
      # Create message
      message = '```'+name+'\n'+text+'\n```'
      console.log message
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
