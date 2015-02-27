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

      @semaphore = Mutex.new
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

    #NOTE: this should be thread-safe
    def provision_socket
      ensure_startup unless @pid

      wait_socket = nil
      checks = 0
      max_retries = 6

      while checks < max_retries
        begin
          checks += 1
          wait_socket = UNIXSocket.new(@port)
          break
        rescue Errno::ENOENT, Errno::ECONNREFUSED, Errno::ENOTDIR
          wait_socket = nil
          sleep 0.5
        end
      end

      if checks >= max_retries
        ensure_shutdown
        raise ExecJS::RuntimeError, "unable to connect to alaska.js server"
      end

      wait_socket
    end

    private

    def ensure_startup
      @semaphore.synchronize {
        return if @pid

        alaska_js_path = File.join(File.dirname(File.expand_path(__FILE__)), '../alaska.js')
        command_options = [alaska_js_path, "--debug #{!!@debug}"] # --other --command-line --options --go --here

        @pid = Process.spawn({"PORT" => @port.to_s}, @nodejs_cmd, *command_options, {:err => :out})

        at_exit do
          ensure_shutdown
        end
      }
    end

    def ensure_shutdown
      return unless @pid

      Process.kill("TERM", @pid) rescue Errno::ECHILD
      Process.wait(@pid) rescue Errno::ECHILD

      @port = nil
      @pid = nil
    end
  end
end
