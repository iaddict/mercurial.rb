#!/usr/bin/env rake
require 'bundler/gem_tasks'

desc "compile mercurial via the ruby extension mechanism"
task :compile do
  sh "ruby ext/mercurial/extconf.rb"
end

namespace :vendor do
  file 'vendor/mercurial' do |f|
    sh "hg clone http://selenic.com/hg #{f.name}"
    sh "hg --repository #{f.name} identify --id > #{f.name}/REVISION"
    rm_rf Dir["#{f.name}/.hg*"]
  end

  task :clobber do
    rm_rf 'vendor/mercurial'
  end

  task :update => [:clobber, 'vendor/mercurial']
end