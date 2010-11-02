# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pasrb}
  s.version = "0.0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Markiz"]
  s.date = %q{2010-11-02}
  s.description = %q{PokerAffiliateSupport api querying via ruby}
  s.email = %q{markizko@gmail.com}
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "lib/pas.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "README", "Rakefile", "autotest/discover.rb", "lib/pas.rb", "pasrb.gemspec", "spec/pas_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/markiz/pasrb}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Pasrb", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pasrb}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{PokerAffiliateSupport api querying via ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 0"])
    else
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<xml-simple>, [">= 0"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<xml-simple>, [">= 0"])
  end
end
