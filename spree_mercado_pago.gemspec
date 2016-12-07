Gem::Specification.new do |s|
  s.name = 'spree_mercado_pago'
  s.version     = '0.2.3'
  s.summary     = 'Spree plugin yo integrate Mercado Pago'
  s.description = 'Integrates Mercado Pago with Spree'
  s.author      = "Manuel Barros Reyes"
  s.files       = `git ls-files -- {app,config,lib,test,spec,features}/*`.split("\n")
  s.homepage    = 'https://github.com/manuca/spree_mercado_pago'
  s.email       = 'manuca@gmail.com'
  s.license     = 'MIT'

  s.add_dependency 'spree_core',  '~> 3.0.6'
  s.add_dependency 'rest-client', '~> 1.7'

  s.add_development_dependency 'ffaker', '~> 1.25'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'rspec-rails',  '~> 2.14'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'coffee-rails', '~> 4.1'
  s.add_development_dependency 'sqlite3', '~> 1.3'

  s.test_files = Dir["spec/**/*"]
end
