AtomGitterView = require("./atom-gitter-view")
MessagePanelView = require("atom-message-panel").MessagePanelView
PlainMessageView = require("atom-message-panel").PlainMessageView
githubUrlFromGit = require("github-url-from-git")
url = require("url")
Gitter = require("node-gitter")
path = require('path')
emojify = require('./emojify')

module.exports =
  configDefaults:
    token: ""
    openOnNewMessage: true
    recentMessagesAtTop: true
    displaySnapshotMessages: true

  emojiFolder: "atom://gitter/node_modules/emojify.js/images/emoji"
  atomGitterView: null
  messagePanelView: null
  gitter: null
  currentRoom: null
  getProjectRepoRoom: ->
    git = atom.project.getRepo()
    # Return if cannot get Repo for Project.
    return null unless git
    console.log "Project has Git repo"
    originUrl = git.getOriginUrl()
    githubUrl = githubUrlFromGit(originUrl)
    return null unless githubUrl
    console.log "Project has GitHub URL", githubUrl
    temp = url.parse(githubUrl).path.split("/")
    userName = temp[1]
    projectName = temp[2]
    userName + "/" + projectName

  initMessagePanelView: ->
    if @messagePanelView?.hasParent()
      console.log "MessagePanelView already exists and is attached."
      return @messagePanelView
    unless @messagePanelView
      console.log "MessagePanelView does not exist."
      @messagePanelView = new MessagePanelView(title: "Gitter")
      @messagePanelView.addClass('native-key-bindings')
      @messagePanelView.attr('tabindex', -1)
      # Display current room
      if @currentRoom
        @setTitle "Gitter - " + @currentRoom.name + " - " + @currentRoom.topic
    console.log "Attaching MessagePanelView"
    @messagePanelView.attach()

  toggleMessagePanel: ->
    if @messagePanelView?.hasParent()
      # Opened
      @closeMessagePanel()
    else
      # Closed
      @openMessagePanel()

  openMessagePanel: ->
    @initMessagePanelView()
    # Force open messages panel
    @messagePanelView.toggle()  if @messagePanelView?.summary.css("display") isnt "none"

  closeMessagePanel: ->
    if @messagePanelView?.hasParent()
      @messagePanelView.close()

  addMessage: (msgView) ->
    console.log "Add Message", msgView
    recentMessagesAtTop = atom.config.get("gitter.recentMessagesAtTop")

    # Add Message
    messagePanelView = @messagePanelView
    messagePanelView.messages.push msgView
    if recentMessagesAtTop
      # Add msgView to top
      messagePanelView.body.prepend msgView
    else
      messagePanelView.body.append msgView

    # Force the summary to be recent
    summary =
      summary: (msgView.message).replace(/<(?:.|\n)*?>/g, "") # Strip HTML
      className: msgView.className

    messagePanelView.setSummary summary
    @

  setTitle: (title) ->
    messagePanelView = @messagePanelView
    messagePanelView.setTitle title
    @

  setSummary: (summary) ->
    messagePanelView = @messagePanelView
    messagePanelView.setSummary summary
    this

  log: (msg, raw, className) ->
    console.log "Gitter Log: ", msg, raw, className
    @addMessage new PlainMessageView(
      message: msg or ""
      raw: (if raw isnt `undefined` then raw else false)
      className: "gitter-message " + className
    )
    @

  info: (msg, raw, className) ->
    @log msg, raw, "text-info " + className
    @

  error: (msg, raw, className) ->
    @log msg, raw, "text-danger " + className
    @

  warn: (msg, raw, className) ->
    @log msg, raw, "text-warning " + className
    @

  displaySetupMessage: ->
    console.log "Gitter Display Setup Message"
    @error "Please setup your Gitter Personal Access Token. See <a href=\"https://developer.gitter.im/apps\">https://developer.gitter.im/apps</a>", true
    @info "If you have not already, <a href=\"https://gitter.im/\">create a Gitter account and sign in</a>. " + "Then go to <a href=\"https://developer.gitter.im/apps\">https://developer.gitter.im/apps</a> and retrieve your Personal Access Token. " + "Enter your Token in the Package Settings. " + "Go to Settings/Preferences ➔ Search for installed package \"Gitter\" and select ➔ Enter your \"Token\".", true
    @

  login: (token) ->
    console.log "Login", token
    @gitter = new Gitter(token)
    unless token
      @displaySetupMessage()
      return false
    @gitter.currentUser().then (user) ->
      @info "You are logged in as " + user.username
      return
    @

  joinProjectRepoRoom: ->
    repoUri = @getProjectRepoRoom()
    unless repoUri
      @warn "Could not determine this project's repository room."
      false
    else
      @joinRoomWithRepoUri repoUri

  joinRoomWithRepoUri: (repoUri) ->
    @gitter.rooms.join repoUri, (error, room) =>
      console.log('joinRoomWithRepoUri', repoUri, error, room);
      if not error and room
        @joinRoom room
      else
        @error "Could not find room with repo URI " + repoUri + "." + ((if !!error then " Error: " + error.message else ""))
        @displaySetupMessage()  if error.message is "Unauthorized"
        false
    return

  joinRoom: (room) ->
    console.log('Join room: ', room);
    unless room
      return @warn "Invalid room. Cannot join."

    @currentRoom = room
    @setTitle "Gitter - " + @currentRoom.name + " - " + @currentRoom.topic
    @addMessage new PlainMessageView(
      message: "Found room: " + room.name
      raw: true
      className: "gitter-message text-success"
    )
    events = room.streaming().chatMessages()

    if atom.config.get('gitter.displaySnapshotMessages')
      console.log "Should display snapshot messages"
      events.on "snapshot", (snapshot) =>
        @addMessage new PlainMessageView(
          message: "Connected to Gitter chat room."
          raw: true
          className: "gitter-message text-success"
        )
        snapshot.forEach @newMessage, @
        return

    events.on "chatMessages", (msg) =>
      if msg.operation is "create"
        @newMessage msg.model
      else
        console.log "Not a new message: " + msg.operation
      return

    return

  newMessage: (msg) ->
    console.log "Gitter New Message: ", msg
    # New message
    user = msg.fromUser
    text = msg.text
    html = msg.html
    sent = msg.sent
    isDeleted = not text
    d = new Date(sent)
    dateStr = d.toDateString() + " " + d.toTimeString()
    message = "<a href=\"https://github.com" + user.url + "\" title=\"" +user.displayName + "\">" + user.username + "</a>" + " - " + dateStr + "<br/>"
    unless isDeleted
      # Not deleted
      message += emojify.replace(html);#, self.emojiFolder, 20)
    else
      # Is deleted
      message += "<em class=\"text-muted\">This message was deleted.</em>"
    msgView = new PlainMessageView(
      message: message
      raw: true
      className: "gitter-message"
    )
    @addMessage msgView

    # Force the summary to be recent
    @setSummary
      summary: user.username + ": " + text
      className: "text-italic"

    # Check if should force open
    openOnNewMessage = atom.config.get("gitter.openOnNewMessage")
    # Open panel on new message
    if openOnNewMessage
      console.log "Should open on this new message."
      @openMessagePanel()
    @

  restart: ->
    console.log "Restart Gitter"
    @initMessagePanelView()
    token = atom.config.get("gitter.token")
    @login token
    @joinProjectRepoRoom()

  activate: (state) ->
    console.log "Activate Gitter"
    # state.atomGitterViewState
    # Setup
    @initMessagePanelView()
    emojify.setConfig({
        #emojify_tag_type : 'div',        # Only run emojify.js on this element
        #only_crawl_id    : null,         # Use to restrict where emojify.js applies
        img_dir          : @emojiFolder,  # Directory for emoji images
        # ignored_tags     : {            # Ignore the following tags
        #     'SCRIPT'  : 1,
        #     'TEXTAREA': 1,
        #     'A'       : 1,
        #     'PRE'     : 1,
        #     'CODE'    : 1
        # }
      });
    @atomGitterView = new AtomGitterView(@)
    token = atom.config.observe("gitter.token", {}, (token) =>
      # Start
      @login token
      @joinProjectRepoRoom()
      return
    )
    return

  deactivate: ->
    @atomGitterView.destroy()

  serialize: ->
    atomGitterViewState: @atomGitterView.serialize()
