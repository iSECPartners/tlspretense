
$: << "lib"

require 'yaml'

CONFIG = YAML.load(File.open('config.yml'))

require 'tasks/ssl'

task :clean => "ssl:clean"
