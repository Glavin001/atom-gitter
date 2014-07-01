{View} = require 'atom'

module.exports =
class AtomGitterInputRoomView extends View
  @content: ->
    @div class: 'gitter overlay from-top panel', =>
      @div
        class: 'panel-heading'
        'Switch to another Gitter room'
      @div class: 'panel-body padded', =>
        @input
          type: 'text'
          class: 'form-control native-key-bindings'
          placeholder: 'Enter the desired Gitter room URI'
          value: ''
          outlet: 'inputRoom'

        @div class: 'block', =>
          @button
            class: 'btn btn-warning'
            click: 'toggle'
            'Close'
          @button
            class: 'btn btn-success'
            click: 'joinProjectRepoRoom'
            'Join Project\'s Repo Room'
          @button
            class: 'btn btn-primary pull-right'
            click: 'switchRoom'
            'Join Room'

  initialize: (serializeState) ->
    @gitter = serializeState

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
      @inputRoom.focus() # Focus on message input

  joinProjectRepoRoom: ->
    @gitter.logger.info "Join project room"
    @gitter.joinProjectRepoRoom()
    @toggle()

  switchRoom: ->
    newRoom = @inputRoom.val()
    @gitter.logger.info "Switch room #{newRoom}"
    if newRoom
      @gitter.joinRoomWithRepoUri(newRoom)
    @toggle()
