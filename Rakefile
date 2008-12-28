require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'rake/testtask'
require 'find'

name = 'ubsafe'
version = '0.3'

gem_spec = Gem::Specification.new do |s|
  s.name = name
  s.version = version
  s.summary = %{ubsafe simplify and automate backup tasks}
  s.description = %{ubsafe was developed by: Tracy Flynn}
  s.author = "Tracy Flynn"
  s.email = "gems@olioinfo.net"
  s.homepage = "http://www.olioinfo.net/projects"

  s.test_files = FileList['test/**/*']

  s.files = FileList["bin/*", 'lib/**/*.rb', 'README', 'doc/**/*.*']
  s.require_paths << 'lib'
  
  s.bindir = "bin"
  s.executables = ['ubsafe']
  s.default_executable = "ubsafe"
  
  s.add_dependency("rspec", "1.1.8")
  s.add_dependency("logging", "0.9.4")
  
  #s.extensions << ""
  #s.extra_rdoc_files = ["README"]
  #s.has_rdoc = true
  #s.platform = "Gem::Platform::Ruby"
  s.required_ruby_version = ">= 1.8.5"
  s.rubyforge_project = "olioinfo"
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
  rm_f FileList['pkg/**/*.*']
end

desc "Run test code"
Rake::TestTask.new(:default) do |t|
  t.libs << "spec"
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
  t.options = '-c --format specdoc'
end

task :install => [:package] do
  sh %{gem install pkg/#{name}-#{version}.gem}
end

task :uninstall do
  sh %{gem uninstall #{name} --VERSION=#{version}}
end
