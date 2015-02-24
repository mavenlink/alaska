require "execjs/runtime"
require "execjs/module"
require "net/http"
require "socket"
require 'benchmark'
require 'tempfile'
require 'json'

class Alaska < ExecJS::Runtime
  class Context < ExecJS::Runtime::Context
    # runtime is an instance of Alaska
    # src is the js code to be eval()'d in the nodejs context
    def initialize(runtime, src = "")
      # third step, repeated .. yes, at least twice for common.css
      @runtime = runtime

      # compile context source, in most cases
      # this is something like the CoffeeScript compiler
      # or the SASS compiler
      eval(src)
    end

    def eval(src, options = {})
      if /\S/ =~ src #IMPORTANT! /\S/ =~ "()" => 0
        exec(src)
      end
    end

    def exec(src, options = {})
      if src.length > 0

        #TODO: figure out better solution
        if src.include?("processor = autoprefixer")
          src = "(function() { #{src} })()"
        end

        src = src.encode('UTF-8', :undef => :replace, :replace => '')
        src = @runtime.compile_source(src)

        # src is either an empty object
        # OR a valid JSON string in the form
        #   ['ok', 'result-of-coffeescript-or-sass-compiler']
        # OR if an error occured
        #   ['err', 'some sort of error to be presented to the developer as a sprockets error']
        #
        status, value = src.empty? ? [] : ::JSON.parse(src, create_additions: false)
        if status == "ok"
          value
        elsif value =~ /SyntaxError:/
          @runtime.ensure_shutdown
          raise ExecJS::RuntimeError, value
        else
          @runtime.ensure_shutdown
          raise ExecJS::ProgramError, value
        end
      else
        ""
      end
    end

    def call(identifier, *args)
      eval "#{identifier}.apply(this, #{::JSON.generate(args)})"
    end
  end

  def initialize(opts = {})
    @debug = opts[:debug]
    @nodejs_cmd = "node"
    @benchmarks = []
  end

  def name
    "Alaska"
  end

  def connection
    @port ||= begin
      srand
      tmpfile = Tempfile.new("alaska")
      path = tmpfile.path
      tmpfile.close
      tmpfile.unlink
      path
    end

    @conn ||= begin
      alaska_js_path = File.join(File.dirname(File.expand_path(__FILE__)), '../alaska.js')
      command_options = [alaska_js_path, "--debug #{!!@debug}"] # --other --command-line --options --go --here

      @pid = Process.spawn({"PORT" => @port.to_s}, @nodejs_cmd, *command_options, {:err => :out})

      s = nil
      checks = 0
      while checks < 128
        begin
          checks += 1
          if File.exists?(@port)
            s = UNIXSocket.new(@port)
          else
            sleep 0.5
            next
          end
          break
        rescue Errno::ENOENT, Errno::ECONNREFUSED
          s = nil
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

      s
    end
  end

  def compile_source(contents)
    out = nil
    @benchmarks << Benchmark.measure {
      sock = Net::BufferedIO.new(connection)
      request = Net::HTTP::Post.new("/")
      request['Connection'] = 'keep-alive'
      request.body = contents
      request.exec(sock, "1.1", "/")

      begin
        response = Net::HTTPResponse.read_new(sock)
      end while response.kind_of?(Net::HTTPContinue)

      response.reading_body(sock, request.response_body_permitted?) { }
      out = response.body
    }
    out
  end

  def available?
    # this must return true to be enabled
    `which #{@nodejs_cmd}`.strip.length > 0
  end

  def deprecated?
    false
  end

  def stats
    if @debug
      avg_str = "N/A"
      if @benchmarks.size > 0
        avg = @benchmarks.inject(0.0) { |sum, el| sum + (el.total) } / @benchmarks.size
        avg_str = avg.round(4).to_s
      end
      puts "alaska shutdown... #{@benchmarks.length} assets pipelined through alaska.js: #{avg_str}s average response time"
    end
  end

  def ensure_shutdown
    if @pid
      stats
      #Process.detach(@pid) rescue Errno::ECHILD
      Process.kill("TERM", @pid) #rescue Errno::ECHILD
      Process.wait(@pid) #rescue Errno::ECHILD
      @conn.close unless @conn.nil? || @conn.closed?
      @port = nil
      @conn = nil
      @pid = nil
    end
  end
end
