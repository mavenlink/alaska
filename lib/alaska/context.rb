require 'net/http'
require 'socket'
require 'tempfile'
require 'json'

require 'execjs/runtime'
require 'execjs/module'

module Alaska
  class Context < ExecJS::Runtime::Context
    # runtime is an instance of Alaska
    # src is the js code to be eval()'d in the nodejs context
    def initialize(runtime, src = "") # third step, repeated .. yes, at least twice for common.css
      @runtime = runtime

      # compile context source, in most cases
      # this is something like the CoffeeScript compiler
      # or the SASS compiler
      eval(src)
    end

    def eval(src)
      if /\S/ =~ src #IMPORTANT! /\S/ =~ "()" => 0
        exec(src)
      end
    end

    def exec(src)
      return "" unless src.length > 0

      src = src.encode('UTF-8', :undef => :replace, :replace => '')
      src = compile_source(src)

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
        raise ExecJS::RuntimeError, value
      else
        raise ExecJS::ProgramError, value
      end
    end

    def call(identifier, *args)
      eval "#{identifier}.apply(this, #{::JSON.generate(args)})"
    end

    private

    def compile_source(contents)
      sock = Net::BufferedIO.new(@runtime.provision_socket)
      request = Net::HTTP::Post.new("/")
      request['Connection'] = 'close'
      request.body = contents
      request.exec(sock, "1.1", "/")

      begin
        response = Net::HTTPResponse.read_new(sock)
      end while response.kind_of?(Net::HTTPContinue)

      response.reading_body(sock, request.response_body_permitted?) { }
      sock.close
      response.body
    end
  end
end
