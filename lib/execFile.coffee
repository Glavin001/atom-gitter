vm = require("vm")
fs = require("fs")
module.exports = (path) ->
  data = fs.readFileSync(path, {
    encoding: 'utf8'
    });
  script = vm.createScript(data, 'execFile.vm');
  script.runInThisContext();
  this
