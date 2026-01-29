source "https://rubygems.org"

gem "fastlane"
gem "pry" # Required by fastlane-plugin-match_keystore
gem "cocoapods" # For iOS dependency management

# Load plugins from Pluginfile
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
