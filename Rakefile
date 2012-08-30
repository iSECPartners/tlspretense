
$: << "lib"

desc "Generate a suite of test certificates"
task :ssl do
  sh "bin/generate_test_certs.rb"
end

desc "Clean up by deleting the 'certs' directory."
task :clean do
  rm_r "certs"
end
