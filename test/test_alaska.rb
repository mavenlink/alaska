require 'minitest/autorun'
require 'minitest/spec'
require 'alaska'
require 'execjs'

describe Alaska do
  before do
    @alaska = Alaska::Runtime.new(:debug => false)
    @alaska_context = @alaska.context_class.new(@alaska)
    @return_42 = "(function() { var f = 42; return 42;})()"
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

  it "should function ok with threads and execjs runtime" do
    ExecJS.runtime = @alaska

    context_a = ExecJS.compile("")

    result_a = context_a.call("(function(a) { return a; })", 123)

    result_a.must_equal 123

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
