require "execjs/runtime"
require "execjs/module"

module Alaska
  class Runtime < ExecJS::Runtime
    attr_accessor :debug, :nodejs_cmd, :port

    def initialize(opts = {})
      @debug = opts[:debug]
      @nodejs_cmd = "node"
      @port = begin
        srand
        tmpfile = Tempfile.new("alaska")
        path = tmpfile.path
        tmpfile.close
        tmpfile.unlink
        path
      end

      run_server
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

    def provision_socket
      UNIXSocket.new(@port)
    end

    private

    def run_server
      alaska_js_path = File.join(File.dirname(File.expand_path(__FILE__)), '../alaska.js')
      command_options = [alaska_js_path, "--debug #{!!@debug}"] # --other --command-line --options --go --here

      @pid = Process.spawn({"PORT" => @port.to_s}, @nodejs_cmd, *command_options, {:err => :out})

      wait_socket = nil
      checks = 0
      while checks < 128
        begin
          checks += 1
          if File.exists?(@port)
            wait_socket = UNIXSocket.new(@port)
          else
            sleep 0.5
            next
          end
          break
        rescue Errno::ENOENT, Errno::ECONNREFUSED
          wait_socket = nil
        end
      end

      if checks > 127
        ensure_shutdown
        raise ExecJS::RuntimeError, "unable to connect to alaska.js server"
      end

      trap('INT') {
        ensure_shutdown
      }

      at_exit do
        ensure_shutdown
      end

      wait_socket.close && wait_socket.closed?
    end

    def ensure_shutdown
      return unless @pid

      Process.kill("TERM", @pid) #rescue Errno::ECHILD
      Process.wait(@pid) #rescue Errno::ECHILD

      @port = nil
      @pid = nil
    end
  end
end
