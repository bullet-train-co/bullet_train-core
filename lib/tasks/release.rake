desc "Cut a release."
task :release do
  puts `bump patch`
  puts `gem build`
  puts `gem push *.gem`
  puts `rm *.gem`
  puts `git push origin main`
end
