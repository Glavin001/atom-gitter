var https = require('https');
var request = require('request');
var events = require('events');
var _ = require('lodash');

module.exports = function(token) {

  var v1 = {
      rooms: function(callback) {

          var options = {
            url: 'https://api.gitter.im/v1/rooms',
            method:   'GET',
            headers:  {'Authorization': 'Bearer ' + token},
          };
          request(options, function(error, response, body) {
            try {
              var json = JSON.parse(body);
              callback(error, json);
            } catch (e) {
              callback(new Error(body), null);
            }
          });
      },
      roomWithRepoUri: function(uri, callback) {
        var self = this;
        self.rooms(function(error, rooms) {
          if (error) {
            return callback(error, null);
          }

          // Iterate over all rooms
          var room = _.find(rooms, function(room) {
            // Find REPO room with correct URI
            //console.log(room, uri);
            if (room.githubType === "REPO" && room.uri === uri) {
              return true;
            }
            else
            {
              return false;
            }
          });

          return callback(null, room);

        });
      },
      room: function(roomId) {
        return {
          stream: function(resource) {

            var streamEventEmitter = new events.EventEmitter();

            var heartbeat = " \n";

            var options = {
              hostname: 'stream.gitter.im',
              port:     443,
              path:     '/v1/rooms/' + roomId + '/' + resource,
              method:   'GET',
              headers:  {'Authorization': 'Bearer ' + token},
              strictSSL: false,
              secureProtocol: 'SSLv3_client_method'
            };

            var req = https.request(options, function(res) {
              streamEventEmitter.on('destroy', function() {
                res.destroy();
              });
              streamEventEmitter.emit('connected');

              res.on('data', function(chunk) {
                var msg = chunk.toString();
                //console.log(msg);
                if (msg !== heartbeat) {
                  //console.log('Message: ' + msg);
                  try {
                    var json = JSON.parse(msg);
                    //console.log('Message: '+JSON.stringify(json, undefined, 4));
                    streamEventEmitter.emit('message', null, json);
                  } catch (e) {
                    console.error(e);
                    console.log(msg);
                    streamEventEmitter.emit('message', e, null);
                  }
                } else {
                  //console.log('Heartbeat');
                  streamEventEmitter.emit('heartbeat');
                }
              });

            });

            req.on('error', function(e) {
              //console.log('Something went wrong: ' + e.message);
              streamEventEmitter.emit('error', e);
            });
            req.on('end', function() {
              streamEventEmitter.emit('closed');
            });
            req.on('finish', function() {
              streamEventEmitter.emit('closed');
            });

            req.end();

            return streamEventEmitter;

          }
        };
      }
  };

  return {
    v1: v1
  };

};
