# Alaska

At Mavenlink we utilize the rails3 asset pipeline (known as sprockets) to compile our coffeescript into javascript. We began charting the time spent waiting for our application to load (and compile coffeescript) over the past 6 months and determined that if we let the trend continue, we would reach "peak coffeescript production"... meaning our developers would literally be spending more time waiting for their coffeescript to compile per page load, than spent looking at the results! By default, the execjs runtime runs a separate node process for each asset that needs to be compiled, reloading the compiler every time. Instead, `Alaska` sets up a persistent server process with the compiler already loaded. This greatly reduces the overall time spent turning coffeescript into javascript.

# Peak Coffeescript

To combat this trend, we developed `alaska` ... the persistent execjs runtime used for coffeescript compilation. The mechanism used is fundamentally different than the default execjs runtime. The differences are outlined below.

## ExecJS::ExternalRuntime

In the default execjs runtime, coffeescript files are converted to javascript files roughly as follows:

1. The sprockets system determines which file needs to be updated
2. An ExecJS::ExternalRuntime::Context is created with the javascript source of the coffeescript compiler as an instance variable.
3. For each file sprockets determines needs to be updated, a new temporary file is created that contains the contexts coffeescript compilation module AND the original coffeescript source code
4. The node interperater is then executed with this tempory file as the argument, and the standard output of that process is delivered back to the sprockets system
5. Sprockets continues with this process for each remaining file, invoking the /usr/bin/node process for each file to be compiled.

To break this down into laymens terms, it means that for every gallon of oil (compiled coffeescript) we want to pull out of the ground, we have to send a truck, with its own drill, out to the location.
It should be immediately apparent that this approach will begin to be slower especially as more and more coffeescript is being produced.

## ExecJS::Alaska::Runtime

In contrast to the default execjs runtime, the alaska runtime constructs a persistent pipeline to the nodejs interepreter, greatly reducing roundtrip time of coffeescript compliation.

1. The sprockets system determines which file needs to be updated (it should be noted that this gem does not alter anything with the sprockets module)
2. An ExecJS::Alaska::Context is created with the javascript source of the coffeescript compiler, a seperate nodejs daemon is spawned in the background, and a http server is started on a local UNIX socket for communication.
3. The initial coffeescript compilation module is then loaded _once_ in the nodejs runtime
4. For each file to be compiled, a http request is made with the request body set to the coffeescript, the response body is the compiled javascript, which is delivered back to sprockets

With this caching of the coffeescript compilation module, and the persistent nodejs compliation server process, we can reduce the roundtrip time for each coffeescript compilation down to several milliseconds (on average in mavenlink's primary rails application the roundtrip time is 16ms)

In summary, the difference in mechanism is very similar to the differences between traditional CGI vs. FCGI

# Getting Started

First you must declare the dependency in your gem management system, for instance your `Gemfile` should be modified to include

    gem 'alaska', :git => 'git@github.com:mavenlink/alaska.git'

Then in a rails initializer file (e.g. `config/initializers/execjs.rb`) declare the `ExecJS.runtime` to be an instance of `Alaska::Runtime`

    require 'alaska'

    if Rails.env == "development" || Rails.env == "test" || ENV["RAILS_GROUPS"] == "assets"
      # use alaska.js pipelining only when precompiling assets
      ExecJS.runtime = Alaska::Runtime.new(:debug => true)
    end

Since this only modifies the `ExecJS` runtime, you should not have to change any of your workflow to make use of `alaska`

If you specify `:debug => true` you will additionally see in your `rails server` output some helpful details on the operation of the pipeline, e.g.

    Listening on port /tmp/alaska20150223-8969-ds0fhl
    alaska.js started

## DRILL BABY DRILL!
