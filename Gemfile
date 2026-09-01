source "https://rubygems.org"

gem "fastlane", "~> 2.238.0"
gem "cocoapods", "~> 1.17.0"

# Load plugins from Pluginfile
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
