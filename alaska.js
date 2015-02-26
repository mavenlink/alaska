var vm = require('vm');
var http = require("http");

var sandbox = vm.createContext({ console: {log: console.log}});
var undefinedString = 'undefined';
var ok = 'ok';
var endEvent = 'end';
var dataEvent = 'data';
var okString = '["ok"]';
var errString = '["err"]';
var contextOptions = {displayErrors: true};
var debugOpt = '--debug true';
var debug = false;

process.argv.forEach(function (val, index, array) {
  //console.log(index + ': ' + val);
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
  //req.shouldKeepAlive = fal;
  var contents = new String();
  req.on(dataEvent, function (dataIn) {
    contents += dataIn;
  });
  req.on(endEvent, function () {
    try {
      var result = vm.runInContext(contents, sandbox, contextOptions);
      if (typeof(result) == undefinedString && result !== null) {
        webPrint(res, okString);
      } else {
        try {
          webPrint(res, JSON.stringify([ok, result]));
        } catch (err) {
          webPrint(res, errString);
        }
      }
    } catch(err) {
      webPrint(res, JSON.stringify(["err", err.toString()]));
    }
  });
});

var port = process.env.PORT || 3001;
//server.timeout = 0;
server.listen(port);

if (debug) {
  console.log('Listening on port', port);
  console.error('alaska.js started');
}
