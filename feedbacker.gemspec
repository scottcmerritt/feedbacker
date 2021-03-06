require_relative "lib/feedbacker/version"

Gem::Specification.new do |spec|
  spec.name        = "feedbacker"
  spec.version     = Feedbacker::VERSION
  spec.authors     = ["Developer"]
  spec.email       = ["dev@meritocracyconsulting.com"]
  #spec.homepage    = "TODO"
  spec.summary     = "Facilitates feedback"
  #spec.description = "TODO: Description of Feedbacker."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  #spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4"

  spec.add_dependency 'devise' #, '>= 3.0'
  spec.add_dependency 'acts_as_commentable_with_threading'
  spec.add_dependency 'kaminari'
  spec.add_dependency 'diffy'
end
