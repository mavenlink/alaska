Gem::Specification.new do |s|
  s.name        = 'alaska'
  s.version     = '1.1.0'
  s.date        = '2016-05-28'
  s.summary     = "persistent ExecJS runtime"
  s.description = "uses a single shared nodejs process to handle ExecJS::Runtime evaluation"
  s.authors     = ["Jon Bardin", "Stephen Grider", "Ville Lautanala", "Giovanni Bonetti"]
  s.email       = 'diclophis@gmail.com'
  s.files       = ["alaska.js", "lib/alaska/runtime.rb", "lib/alaska/context.rb"]
  s.homepage    = "https://github.com/mavenlink/alaska"
  s.license     = 'MIT'

  s.add_dependency 'execjs', '~> 2.7'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'minitest', '~> 5.5'
end
