var AtomGitterView, Git, githubUrlFromGit, gitterStream, url;

AtomGitterView = require('./atom-gitter-view');

//var atom = require('atom');
//var Git = atom.Git;

githubUrlFromGit = require('github-url-from-git');

url = require('url');

gitter = require('./gitter');

module.exports = {
  configDefaults: {
    token: ""
  },
  atomGitterView: null,
  activate: function(state) {
    this.atomGitterView = new AtomGitterView(state.atomGitterViewState);

    var token = atom.config.get('gitter.token');

    if (!token) {
      console.log('Please setup your Gitter Token.');
      return;
    }

    var git = atom.project.getRepo();
    var originUrl = git.getOriginUrl();
    var githubUrl = githubUrlFromGit(originUrl);
    var temp = url.parse(githubUrl).path.split('/');
    var userName = temp[1];
    var projectName = temp[2];
    console.log(userName);
    console.log(projectName);
    var Gitter = new gitter(token);
    Gitter.v1.roomWithRepoUri(userName+'/'+projectName, function(error, room) {
        //console.log(error, room);
        if (room) {
          console.log('Found room:', room);
          var stream = Gitter.v1.room(room.id).stream('chatMessages');
          stream.on('message', function(error, msg) {
            console.log('Message: '+JSON.stringify(msg, undefined, 4));
          });
          stream.on('heartbeat', function() {
            console.log('Heartbeat');
          });
          stream.on('error', function(error) {
            console.log(error);
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
