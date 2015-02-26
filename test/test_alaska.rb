require 'minitest/autorun'
require 'minitest/spec'
require 'alaska'
require 'execjs'

describe Alaska do
  before do
    @alaska = Alaska::Runtime.new(:debug => false)
    @alaska_context = @alaska.context_class.new(@alaska)
    @return_42 = "(function() { var f = 42; return 42;})()"
    ExecJS.runtime = @alaska
  end

  it "talks to nodejs and allows js to be executed" do
    js_result = @alaska_context.eval(@return_42)
    js_result.must_equal 42
  end

  it "raises an ExecJS::ProgramError on error" do
    lambda {
      @alaska_context.eval("(function() { throw new Error('foo\\nbar', 0, 'test.js'); })()")
    }.must_raise(ExecJS::ProgramError)
  end

  it "requires js to be in a self-executing function" do
    js_result = -1

    lambda {
      js_result = @alaska_context.eval("return true;")
    }.must_raise(ExecJS::RuntimeError)

    js_result.must_equal -1
  end

  it "shutsdown the connection on error, but re-establishes on subsequent calls" do
    js_result = @alaska_context.eval(@return_42)
    js_result.must_equal 42

    lambda {
      js_result = @alaska_context.eval("return true;")
    }.must_raise(ExecJS::RuntimeError)

    js_result = @alaska_context.eval(@return_42)
    js_result.must_equal 42
  end

  it "should function as an execjs runtime" do
    context_a = ExecJS.compile("")
    result_a = context_a.call("(function(a) { return a; })", 123)
    result_a.must_equal 123
  end

  it "should be thread safe when sharing context between threads" do
    thread_count = 128
    threads = []
    semaphore = Mutex.new
    results = []

    context = ExecJS.compile("var a = 1.0;") # this asserts that the context is shared

    thread_count.times { |index|
      threads << Thread.new {
        result = context.call("(function(b) { return (a * b); })", index)
        semaphore.synchronize {
          results << result
        }
      }
    }

    threads.each { |t| t.join }

    sum = results.inject(0) { |result, element| result + element }

    sum.must_equal(8128) # http://www.wolframalpha.com/input/?i=127th+trianglur+number
  end

  it "should be thread safe when creating new contexts in threads" do
    thread_count = 128
    threads = []
    semaphore = Mutex.new
    results = []

    thread_count.times { |index|
      threads << Thread.new {
        context = ExecJS.compile("var a = 2.0;") # this asserts that the context is shared
        result = context.call("(function(b) { return (a * b); })", index)
        semaphore.synchronize {
          results << result
        }
      }
    }

    threads.each { |t| t.join }

    sum = results.inject(0) { |result, element| result + element }

    sum.must_equal(8128 * 2) # http://www.wolframalpha.com/input/?i=127th+trianglur+number
  end

  it "should not break if exception occurs in thread" do
    context_a = ExecJS.compile("")

    g_err_a = nil
    g_err_b = nil

    make_program_error_thread = Thread.new {
      begin
        b = context_a.call("(function() { asd() })")
      rescue => err_a
        g_err_a = err_a
      end
    }

    context_b = ExecJS.compile("")

    begin
      c = context_b.call("(function() { asd) })")
    rescue => err_b
      g_err_b = err_b
    end

    make_program_error_thread.join

    g_err_a.must_be_kind_of(ExecJS::ProgramError)
    g_err_b.must_be_kind_of(ExecJS::RuntimeError)
  end
end
