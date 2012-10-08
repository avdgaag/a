gem_group :development, :test do
  gem 'jasmine'
  gem 'factory_girl_rails'
  gem 'rspec-rails'
end

gem_group :development do
  gem 'guard-rspec'
  gem 'guard-pow'
  gem 'jasmine-headless-webkit'
  gem 'guard-jasmine-headless-webkit'
  gem 'growl'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'capybara'
  gem 'shoulda-matchers'
  gem 'capybara-webkit'
end

gem_group :assets do
  gem 'rocks'
  gem 'bourbon'
end

gem 'devise'
gem 'yard-rails', require: false
gem 'haml'
gem 'haml-rails'
gem 'draper'
gem 'kaminari'
gem 'simple-navigation'
gem 'simple_form'

# Rspec support files
create_file 'spec/support/capybara_headless_webkit', <<-RUBY
RSpec.configure do |config|
  Capybara.javascript_driver = :webkit
end
RUBY

create_file 'spec/support/factory_girl.rb', <<-RUBY
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
RUBY

create_file 'spec/support/database_cleaner.rb', <<-RUBY
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
RUBY

create_file 'spec/support/devise.rb', <<-RUBY
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end
RUBY

inject_into_file 'config/environments/test.rb', before: /^end$/ do
  "\n  config.action_mailer.default_url_options = { host: 'example.com' }\n"
end

inject_into_file 'config/environments/development.rb', before: /^end$/ do
  "\n  config.action_mailer.default_url_options = { host: 'localhost:3000' }\n"
end

inject_into_file 'config/application.rb', after: 'config.assets.enabled = true' do
  "\n    config.assets.initialize_on_precompile = false\n"
end

route 'root to: "sessions#new"'

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
  g.template_engine     :haml
  g.test_framework      :rspec, fixture: true, fixture_replacement: :factory_girl
  g.view_specs          false
  g.helper_specs        false
  g.helper              false
  g.javascripts         false
  g.stylesheets         false
  g.fixture_replacement :factory_girl
  g.assets              false
end
RUBY

create_file 'app/decorators/ApplicationDecorator', <<-RUBY
class ApplicationDecorator < Draper::Base
end
RUBY

remove_file 'README'
remove_file 'doc/README_FOR_APP'
remove_file 'public/index.html'
remove_file 'app/assets/images/rails.png'

role = ask('What role should be used for the database configuration?')
run 'cp config/database.yml config/database.yml.example'
gsub_file 'config/database.yml', /  username: .+$/, "  username: #{role}"
append_to_file '.gitignore', 'config/database.yml'

run 'bundle install --binstubs'
run 'bundle update'

rake 'db:create'

generate 'rspec:install'
append_to_file '.rspec', '--order rand'
generate 'devise:install'
generate 'devise user'
generate 'simple_form:install'
generate 'navigation_config'
generate 'jasmine:install'
generate 'kaminari:config'
run 'bundle exec guard init'

rake 'db:migrate'
rake 'db:test:prepare'

git :init
git add: '.'
git commit: '-aqm "Initial commit of new Rails app"'
