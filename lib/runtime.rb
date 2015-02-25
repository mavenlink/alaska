require "execjs/runtime"
require "execjs/module"

module Alaska
  class Runtime < ExecJS::Runtime
    attr_accessor :debug, :nodejs_cmd

    def initialize(opts = {})
      @debug = opts[:debug]
      @nodejs_cmd = "node"
    end

    def name
      "Alaska"
    end

    def available?
      #NOTE: this is brittle in terms of cross platform detection of node executable
      `which #{@nodejs_cmd}`.strip.length > 0 # this must return true to be enabled
    end

    def deprecated?
      false
    end

    def context_class
      Alaska::Context
    end
  end
end
