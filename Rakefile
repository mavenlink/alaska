require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
  t.warning = ENV["PEDANTIC"] || ENV["CI"]
end

desc "Run tests"
task :default => :test
