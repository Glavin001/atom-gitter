path = require('path')
# Include the Emojify.js
module.exports = (() ->
  # Emojify
  execFile = require('./execFile');
  emojifyPath = path.resolve(__dirname, '../node_modules/emojify.js/dist/js/emojify.js');
  execFile(emojifyPath).emojify;
)()
