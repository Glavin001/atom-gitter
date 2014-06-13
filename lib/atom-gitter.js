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
  activate: function(state) {
    this.atomGitterView = new AtomGitterView(state.atomGitterViewState);

    var messages = new MessagePanelView({
      title: 'Gitter'
    });
    messages.attach();
    function addMessage(msgView) {
      var recentMessagesAtTop = atom.config.get('gitter.recentMessagesAtTop');
      // Add Message
      messages.messages.push(msgView);
      if (recentMessagesAtTop) {
        // Add msgView to top
        messages.body.prepend(msgView);
      } else {
        messages.body.append(msgView);
      }
      // Force the summary to be recent
      messages.setSummary(msgView.getSummary());
    }

    var token = atom.config.get('gitter.token');

    if (!token) {
      //console.log('Please setup your Gitter Token.');
      addMessage(new PlainMessageView({
        message: 'Please setup your Gitter Personal Access Token. See https://developer.gitter.im/apps',
        raw: true,
        className: 'gitter-message text-danger'
      }));
      return;
    }

    var git = atom.project.getRepo();
    var originUrl = git.getOriginUrl();
    var githubUrl = githubUrlFromGit(originUrl);
    var temp = url.parse(githubUrl).path.split('/');
    var userName = temp[1];
    var projectName = temp[2];
    //console.log(userName);
    //console.log(projectName);
    var Gitter = new gitter(token);
    Gitter.v1.roomWithRepoUri(userName + '/' + projectName, function(error, room) {
      //console.log(error, room);
      if (room) {
        console.log('Found room:', room);

        messages.setTitle('Gitter - ' + room.name + ' - ' + room.topic);
        addMessage(new PlainMessageView({
          message: 'Found room: ' + room.name,
          raw: true,
          className: 'gitter-message text-success'
        }));

        var stream = Gitter.v1.room(room.id).stream('chatMessages');
        stream.on('connected', function() {
          addMessage(new PlainMessageView({
            message: 'Connected to Gitter chat room.',
            raw: true,
            className: 'gitter-message text-success'
          }));
        });
        stream.on('message', function(error, msg) {
          console.log('Message: ' + JSON.stringify(msg, undefined, 4));

          if (msg === null) {
            addMessage(new PlainMessageView({
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
              addMessage(msgView);
              // Force the summary to be recent
              messages.setSummary({
                'summary': msg.fromUser.username + ': ' + msg.text,
                'className': 'text-italic'
              });

              // Check if should force open
              var openOnNewMessage = atom.config.get('gitter.openOnNewMessage');
              if (openOnNewMessage && messages.summary.css('display') !== 'none') {
                // Open panel on new message
                messages.toggle();
              }
          }

        });
        stream.on('heartbeat', function() {
          console.log('Heartbeat');
        });
        stream.on('error', function(error) {
          console.log(error);
          addMessage(new PlainMessageView({
            message: 'Error: ' + error.message,
            className: 'gitter-message text-danger'
          }));
        });
        stream.on('close', function() {
          addMessage(new PlainMessageView({
            message: 'Connection closed.',
            className: 'gitter-message text-danger'
          }));
        });

      }
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
