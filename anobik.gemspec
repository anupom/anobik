# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{anobik}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Anupom Syam"]
  s.date = %q{2009-05-24}
  s.description = %q{Rack middleware Ruby micro-framework}
  s.email = %q{anupom.syam@gmail.com}
  s.extra_rdoc_files = ["CHANGELOG.txt", "lib/anobik.rb", "lib/rack/anobik.rb", "README.rdoc"]
  s.files = ["test/spec_rack_anobik.rb", "Rakefile", "CHANGELOG.txt", "lib/anobik.rb", "lib/rack/anobik.rb", "anobik-server", "Manifest", "README.rdoc", "anobik.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/anupom/anobik}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Anobik", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{anobik}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Rack middleware Ruby micro-framework}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
  end
end
