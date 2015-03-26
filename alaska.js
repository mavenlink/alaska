var vm = require('vm');
var http = require("http");
var sandbox = vm.createContext({ console: {log: console.log}});

var contextOptions = {displayErrors: true};
var debugOpt = '--debug true';
var debug = false;

process.argv.forEach(function (val, index, array) {
  if (debugOpt === val) {
    debug = true;
  }
});

var webPrint = function(res, respBody) {
  res.writeHead(200, {'Connection': 'keep-alive'});
  res.write(respBody);
  res.end();
};

var server = http.createServer(function(req, res) {
  var contents = '';

  req.on('data', function (dataIn) {
    contents += dataIn;
  });

  req.on('end', function () {
    try {
      var result = vm.runInContext(contents, sandbox, contextOptions);
      if (typeof(result) == 'undefined' && result !== null) {
        webPrint(res, '["ok"]');
      } else {
        try {
          webPrint(res, JSON.stringify(['ok', result]));
        } catch (err) {
          webPrint(res, '["err"]');
        }
      }
    } catch(err) {
      webPrint(res, JSON.stringify(["err", err.toString()]));
    }
  });
});

var port = process.env.PORT || 3001;
server.listen(port);

if (debug) {
  console.log('Listening on port:', port);
  console.error('Alaska.js started.  Piping coffee to warmer climates.');
}
