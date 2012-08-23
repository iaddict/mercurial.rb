require 'mkmf'
create_makefile('mercurial')

make = `which gmake`.chomp
make = `which make`.chomp unless $?.success?

Dir.chdir(File.expand_path '../../../vendor/mercurial', __FILE__) do
  puts `#{make} local`
end
exit $?.exitstatus
