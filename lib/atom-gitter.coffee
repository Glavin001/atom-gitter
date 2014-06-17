AtomGitterView = require("./atom-gitter-view")
MessagePanelView = require("atom-message-panel").MessagePanelView
PlainMessageView = require("atom-message-panel").PlainMessageView
githubUrlFromGit = require("github-url-from-git")
url = require("url")
Gitter = require("node-gitter")
path = require('path')
emojify = require('./emojify')
console.log emojify

module.exports =
  configDefaults:
    token: ""
    openOnNewMessage: true
    recentMessagesAtTop: true

  emojiFolder: "atom://gitter/node_modules/emojify.js/images/emoji"
  atomGitterView: null
  messagePanelView: null
  gitter: null
  currentRoom: null
  getProjectRepoRoom: ->
    git = atom.project.getRepo()

    # Cannot get Repo for Project.
    return null  unless git
    originUrl = git.getOriginUrl()
    githubUrl = githubUrlFromGit(originUrl)
    temp = url.parse(githubUrl).path.split("/")
    userName = temp[1]
    projectName = temp[2]

    #console.log(userName);
    #console.log(projectName);
    userName + "/" + projectName

  initMessagePanelView: ->
    messagePanelView = new MessagePanelView(title: "Gitter")
    messagePanelView.attach()
    @messagePanelView = messagePanelView
    this

  addMessage: (msgView) ->
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
    #var summary = msgView.getSummary();
    summary =
      summary: (msgView.message).replace(/<(?:.|\n)*?>/g, "") # Strip HTML
      className: msgView.className

    messagePanelView.setSummary summary
    this

  setTitle: (title) ->
    messagePanelView = @messagePanelView
    messagePanelView.setTitle title
    this

  setSummary: (summary) ->
    messagePanelView = @messagePanelView
    messagePanelView.setSummary summary
    this

  log: (msg, raw, className) ->
    @addMessage new PlainMessageView(
      message: msg or ""
      raw: (if raw isnt `undefined` then raw else false)
      className: "gitter-message " + className
    )
    self

  info: (msg, raw, className) ->
    @log msg, raw, "text-info " + className
    self

  error: (msg, raw, className) ->
    @log msg, raw, "text-danger " + className
    self

  warn: (msg, raw, className) ->
    @log msg, raw, "text-warning " + className
    self

  displaySetupMessage: ->
    self = this
    self.error "Please setup your Gitter Personal Access Token. See <a href=\"https://developer.gitter.im/apps\">https://developer.gitter.im/apps</a>", true
    self.info "If you have not already, <a href=\"https://gitter.im/\">create a Gitter account and sign in</a>. " + "Then go to <a href=\"https://developer.gitter.im/apps\">https://developer.gitter.im/apps</a> and retrieve your Personal Access Token. " + "Enter your Token in the Package Settings. " + "Go to Settings/Preferences ➔ Search for installed package \"Gitter\" and select ➔ Enter your \"Token\".", true
    self

  login: (token) ->
    console.log "Login", token
    self = this
    self.gitter = new Gitter(token)
    unless token
      self.displaySetupMessage()
      return false
    self.gitter.currentUser().then (user) ->
      self.info "You are logged in as " + user.username
      return

    self

  joinProjectRepoRoom: ->
    self = this
    repoUri = self.getProjectRepoRoom()
    unless repoUri
      self.warn "Could not determine this project's repository room."
      false
    else
      self.joinRoomWithRepoUri repoUri

  joinRoomWithRepoUri: (repoUri) ->
    self = this
    self.gitter.rooms.join repoUri, (error, room) ->

      #console.log(error, room);
      if not error and room
        self.joinRoom room
      else
        self.error "Could not find room with repo URI " + repoUri + "." + ((if !!error then " Error: " + error.message else ""))
        self.displaySetupMessage()  if error.message is "Unauthorized"
        false

    return

  joinRoom: (room) ->
    self = this

    #console.log('Found room:', room);
    self.setTitle "Gitter - " + room.name + " - " + room.topic
    self.addMessage new PlainMessageView(
      message: "Found room: " + room.name
      raw: true
      className: "gitter-message text-success"
    )
    events = room.streaming().chatMessages()
    self.currentRoom = room
    events.on "snapshot", (snapshot) ->
      self.addMessage new PlainMessageView(
        message: "Connected to Gitter chat room."
        raw: true
        className: "gitter-message text-success"
      )
      snapshot.forEach self.newMessage, self
      return

    events.on "chatMessages", (msg) ->
      if msg.operation is "create"
        self.newMessage msg.model
      else
        console.log "Not a new message: " + msg.operation
      return

    return

  newMessage: (msg) ->
    self = this

    # New message
    username = msg.fromUser.username
    text = msg.text
    html = msg.html
    sent = msg.sent
    isDeleted = not text
    d = new Date(sent)
    dateStr = d.toDateString() + " " + d.toTimeString()
    message = "<a href=\"https://github.com" + msg.fromUser.url + "\">" + msg.fromUser.username + "</a>" + " - " + dateStr + "<br/>"
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
    self.addMessage msgView

    # Force the summary to be recent
    self.setSummary
      summary: username + ": " + text
      className: "text-italic"


    # Check if should force open
    openOnNewMessage = atom.config.get("gitter.openOnNewMessage")

    # Open panel on new message
    self.messagePanelView.toggle()  if openOnNewMessage and self.messagePanelView.summary.css("display") isnt "none"
    return

  activate: (state) ->
    # state.atomGitterViewState
    @atomGitterView = new AtomGitterView(self)

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
