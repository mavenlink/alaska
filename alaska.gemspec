Gem::Specification.new do |s|
  s.name        = 'alaska'
  s.version     = '0.0.6'
  s.date        = '2015-02-10'
  s.summary     = "caching ExecJS runtime"
  s.description = ""
  s.authors     = ["Jon Bardin"]
  s.email       = 'diclophis@gmail.com'
  s.files       = ["lib/alaska.rb"]
  s.homepage    = "https://github.com/mavenlink/alaska"
  s.license     = 'MIT'

  s.add_dependency 'execjs'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'minitest', '~> 5.5.1'
  s.add_development_dependency 'execjs', '~> 2.3.0'
end
