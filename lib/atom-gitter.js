var AtomGitterView, Git, githubUrlFromGit, gitterStream, url;

AtomGitterView = require('./atom-gitter-view');

var MessagePanelView = require('atom-message-panel').MessagePanelView;
var PlainMessageView = require('atom-message-panel').PlainMessageView;

//var atom = require('atom');
//var Git = atom.Git;

githubUrlFromGit = require('github-url-from-git');

url = require('url');

gitter = require('./gitter');

module.exports = {
  configDefaults: {
    token: "",
    openOnNewMessage: true,
    recentMessagesAtTop: true
  },
  atomGitterView: null,
  getProjectRepoRoom: function() {
    var git = atom.project.getRepo();
    if (!git) {
      // Cannot get Repo for Project.
      return null;
    }
    var originUrl = git.getOriginUrl();
    var githubUrl = githubUrlFromGit(originUrl);
    var temp = url.parse(githubUrl).path.split('/');
    var userName = temp[1];
    var projectName = temp[2];
    //console.log(userName);
    //console.log(projectName);
    return userName + '/' + projectName;
  },

  messagePanelView: null,
  initMessagePanelView: function() {
    var messagePanelView = new MessagePanelView({
      title: 'Gitter'
    });
    messagePanelView.attach();
    this.messagePanelView = messagePanelView;
    return this;
  },
  addMessage: function(msgView) {
    var recentMessagesAtTop = atom.config.get('gitter.recentMessagesAtTop');
    // Add Message
    var messagePanelView = this.messagePanelView;
    messagePanelView.messages.push(msgView);
    if (recentMessagesAtTop) {
      // Add msgView to top
      messagePanelView.body.prepend(msgView);
    } else {
      messagePanelView.body.append(msgView);
    }
    // Force the summary to be recent
    //var summary = msgView.getSummary();
    var summary = {
      summary: (msgView.message).replace(/<(?:.|\n)*?>/gm, ''), // Strip HTML
      className: msgView.className
    };
    messagePanelView.setSummary(summary);
    return this;
  },
  setTitle: function(title) {
    var messagePanelView = this.messagePanelView;
    messagePanelView.setTitle(title);
    return this;
  },
  setSummary: function(summary) {
    var messagePanelView = this.messagePanelView;
    messagePanelView.setSummary(summary);
    return this;
  },

  log: function(msg, raw, className) {
    this.addMessage(new PlainMessageView({
      message: msg || '',
      raw: raw !== undefined ? raw : false,
      className: 'gitter-message ' + className
    }));
    return self;
  },
  info: function(msg, raw, className) {
    this.log(msg, raw, 'text-info ' + className);
    return self;
  },
  error: function(msg, raw, className) {
    this.log(msg, raw, 'text-danger ' + className);
    return self;
  },
  warn: function(msg, raw, className) {
    this.log(msg, raw, 'text-warning ' + className);
    return self;
  },

  displaySetupMessage: function() {
    var self = this;
    self.error('Please setup your Gitter Personal Access Token. See <a href="https://developer.gitter.im/apps">https://developer.gitter.im/apps</a>', true);
    self.info('If you have not already, <a href="https://gitter.im/">create a Gitter account and sign in</a>. ' +
      'Then go to <a href="https://developer.gitter.im/apps">https://developer.gitter.im/apps</a> and retrieve your Personal Access Token. ' +
      'Enter your Token in the Package Settings. ' +
      'Go to Settings/Preferences ➔ Search for installed package "Gitter" and select ➔ Enter your "Token".', true);
    return self;
  },

  login: function(token) {
    console.log('Login', token);
    var self = this;
    if (self.gitterStream) {
      // Close existing connections
      self.gitterStream.emit('destroy');
    }
    self.Gitter = new gitter(token);
    if (!token) {
      self.displaySetupMessage();
      return false;
    }
    return self;
  },

  joinProjectRepoRoom: function() {
    var self = this;
    var repoUri = self.getProjectRepoRoom();
    if (!repoUri) {
      self.warn('Could not find this project\'s repository room.');
      return false;
    } else {
      return self.joinRoomWithRepoUri(repoUri);
    }
  },

  joinRoomWithRepoUri: function(repoUri) {
    var self = this;
    self.Gitter.v1.roomWithRepoUri(repoUri, function(error, room) {
      //console.log(error, room);
      if (room) {
        return self.joinRoom(room);
      } else {
        self.error('Could not find room with repo URI ' + repoUri + '. Error: ' + error.message);
        if (error.message === 'Unauthorized') {
          self.displaySetupMessage();
        }
        return false;
      }
    });
  },

  joinRoom: function(room) {
    var self = this;

    console.log('Found room:', room);

    self.setTitle('Gitter - ' + room.name + ' - ' + room.topic);
    self.addMessage(new PlainMessageView({
      message: 'Found room: ' + room.name,
      raw: true,
      className: 'gitter-message text-success'
    }));

    var stream = self.Gitter.v1.room(room.id).stream('chatMessages');
    self.gitterStream = stream;
    stream.on('connected', function() {
      self.addMessage(new PlainMessageView({
        message: 'Connected to Gitter chat room.',
        raw: true,
        className: 'gitter-message text-success'
      }));
    });
    stream.on('message', function(error, msg) {
      console.log('Message: ' + JSON.stringify(msg, undefined, 4));

      if (msg === null) {
        self.addMessage(new PlainMessageView({
          message: 'Error reading message.',
          className: 'gitter-message text-danger'
        }));
      } else {
        var html = msg.html;
        var d = new Date(msg.sent);
        var dateStr = d.toDateString() + ' ' + d.toTimeString();
        var message = '<a href="https://github.com' + msg.fromUser.url + '">' + msg.fromUser.username + '</a>' +
          ' - ' + dateStr + '<br/>' + html;

        var msgView = new PlainMessageView({
          message: message,
          raw: true,
          className: 'gitter-message'
        });
        self.addMessage(msgView);
        // Force the summary to be recent
        self.setSummary({
          'summary': msg.fromUser.username + ': ' + msg.text,
          'className': 'text-italic'
        });

        // Check if should force open
        var openOnNewMessage = atom.config.get('gitter.openOnNewMessage');
        if (openOnNewMessage && self.messagePanelView.summary.css('display') !== 'none') {
          // Open panel on new message
          self.messagePanelView.toggle();
        }
      }

    });
    stream.on('heartbeat', function() {
      console.log('Heartbeat');
    });
    stream.on('error', function(error) {
      console.log(error);
      self.addMessage(new PlainMessageView({
        message: 'Error: ' + error.message,
        className: 'gitter-message text-danger'
      }));
    });
    stream.on('closed', function() {
      console.log('Gitter connection closed.');
      // self.addMessage(new PlainMessageView({
      //   message: 'Connection closed.',
      //   className: 'gitter-message text-danger'
      // }));
    });


  },

  activate: function(state) {
    var self = this;

    self.atomGitterView = new AtomGitterView(state.atomGitterViewState);

    // Setup
    self.initMessagePanelView();
    var token = atom.config.observe('gitter.token', {}, function(token) {
      // Start
      self.login(token);
      self.joinProjectRepoRoom();
    });

    return;
  },


  deactivate: function() {
    return this.atomGitterView.destroy();
  },
  serialize: function() {
    return {
      atomGitterViewState: this.atomGitterView.serialize()
    };
  }
};
