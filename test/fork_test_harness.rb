#!/usr/bin/env ruby

require 'alaska'
require 'execjs'

alaska = Alaska::Runtime.new(:debug => false)
alaska_context = alaska.context_class.new(alaska)
ExecJS.runtime = alaska

fork_count = 4

fork_count.times do |i|
  fork do
    context = ExecJS.compile("var a = 2.0;") # this asserts that the context is shared
    result = context.call("(function(b) { return (a * b); })", i)
    exit result #use the exit code to communicate the calculation result
  end
end
  
exit_statuses = Process.waitall

results = []
exit_statuses.each do |pid, status|
  results << status.exitstatus
end

# http://www.wolframalpha.com/input/?i=3rd+trianglur+number
sum = results.inject(0) { |result, element| result + element }

if (sum) == 12
  exit 0
else
  exit 1
end
