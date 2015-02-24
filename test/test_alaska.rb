require 'minitest/autorun'
require 'minitest/spec'
require 'alaska'

describe Alaska do
  before do
    @alaska = Alaska.new(:debug => true)
    @alaska_context = Alaska::Context.new(@alaska)
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
end
