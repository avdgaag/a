gem_group :development do
  gem 'arrate'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'terminal-notifier-guard'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rubocop'
end

gem_group :development, :test do
  gem 'factory_girl_rails', '~> 4.3'
  gem 'rspec-rails', '~> 2.14'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'capybara', '~> 2.2'
  gem 'capybara-webkit', '~> 1.1'
  gem 'spring', '~> 1.1'
  gem 'spring-commands-rspec'
  gem 'simplecov', require: false
end

gem_group :doc do
  gem 'yard', require: false
  gem 'kramdown', require: false
  gem 'gollum', require: false
end

gem 'devise'
gem 'haml-rails'
gem 'draper'
gem 'kaminari'
gem 'simple_form'
gem 'foundation-rails'
gem 'thin'
gem 'pundit'
gem 'foreman'

create_file '.yardopts', <<-OPTS
--title 'Rails Application Documentation'
--readme README.md
--markup markdown
--markup-provider kramdown
--files LICENSE,CHANGELOG
--output-dir doc/app
--no-stats
OPTS

create_file '.rubocop.yml', <<-YAML
AllCops:
  Includes:
    - '**/*.gemspec'
    - '**/Rakefile'
  Excludes:
    - bin/**
    - db/**
    - vendor/**
  RunRailsCops: true

SignalException:
  EnforcedStyle: only_raise

SymbolArray:
  Enabled: true
YAML

create_file 'lib/tasks/rubocop.rake', <<-RUBY
begin
  require 'rubocop/rake_task'
  Rubocop::RakeTask.new
rescue LoadError
  # Rubocop is not available in production. Don't care if it's not there.
end
RUBY

create_file 'lib/tasks/gollum.rake', <<-RUBY
namespace :wiki do
  task :serve do
    sh 'gollum --page-file-dir doc/wiki'
  end
end
RUBY

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

create_file 'spec/support/simplecov.rb', <<-RUBY
require 'simplecov'
SimpleCov.start 'rails' do
  minimum_coverage 95
end
RUBY

create_file 'spec/support/pundit.rb', <<-RUBY
require 'pundit/rspec'
RUBY

create_file 'Procfile', <<-RUBY
web: bin/thin start --port $PORT --environment $RAILS_ENV
RUBY

secret_key = File.read('config/initializers/secret_token.rb')[/'(.+)'/, 1]

create_file '.rbenv-vars', <<-RUBY
PORT=3000
RAILS_ENV=development
RAILS_SECRET_KEY_BASE=#{secret_key}
RUBY

gsub_file 'config/initializers/secret_token.rb', /'.+'/, "ENV.fetch('RAILS_SECRET_KEY_BASE', 'example_key')"

create_file '.gitattributes', '*.rb diff=ruby'

inject_into_file 'config/environments/test.rb', before: /^end$/ do
  "\n  config.action_mailer.default_url_options = { host: 'example.com' }\n"
end

inject_into_file 'config/environments/development.rb', before: /^end$/ do
  "\n  config.action_mailer.default_url_options = { host: 'localhost:3000' }\n"
end

inject_into_file 'app/controllers/application_controller.rb', before: /^end$/ do
  "\n  include Pundit\n  before_filter :authenticate_user!\n  after_filter :verify_authorized, except: :index\n  after_filter :verify_policy_scoped, only: :index\n"
end

inject_into_file 'Gemfile', after: /^source.+$/ do
  "\n\nruby '2.1.1'\n"
end

route 'root to: "devise/sessions#new"'

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
  g.template_engine     :haml
  g.test_framework      :rspec, fixture: true, fixture_replacement: :factory_girl
  g.view_specs          false
  g.helper_specs        false
  g.helper              false
  g.javascripts         false
  g.stylesheets         false
  g.fixture_replacement :factory_girl, dir: 'spec/factories'
  g.assets              false
end
RUBY

initializer 'gollum.rb', <<-RUBY
if Rails.env.development?
  require 'gollum/app'
  Precious::App.set :gollum_path, Rails.root
  Precious::App.set :wiki_options, page_file_dir: 'doc/wiki'
end
RUBY

route "mount Precious::App => '/wiki' if defined?(Precious)"

gsub_file 'Gemfile', /^gem 'turbolinks'.*\n/, ''
gsub_file 'Gemfile', /^gem 'jbuilder'.*\n/, ''
gsub_file 'Gemfile', /^(  )?#.*/, ''
gsub_file 'Gemfile', /^\n/, ''
gsub_file 'app/assets/javascripts/application.js', %r{//= require turbolinks\n}, ''

create_file 'app/decorators/application_decorator.rb', <<-RUBY
class ApplicationDecorator < Draper::Decorator
  def self.collection_decorator_class
    PaginatingDecorator
  end

  # Override Haml's default object notation to use the class name
  # it would have used had an object not been decorated.
  #
  # This removes the need for markup like:
  #
  #     %div[person.person]
  #       ...
  #
  # Instead allowing:
  #
  #     %div[person]
  #       ...
  def haml_object_ref
    model.class.to_s.underscore
  end
end
RUBY

create_file 'app/decorators/paginating_decorator.rb', <<-RUBY
class PaginatingDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_pages, :limit_value
end
RUBY

remove_file 'README.rdoc'
remove_file 'doc/README_FOR_APP'
remove_file 'app/assets/stylesheets/application.css'
remove_file 'app/views/layouts/application.html.erb'
create_file 'app/assets/stylesheets/application.scss'
create_file 'README.md'
create_file 'app/views/layouts/application.html.haml', <<-HAML
!!! 5
%html{ lang: 'en' }
  %head
    %meta{ charset: 'utf-8' }
    %meta{ name: 'viewport', content: 'width=device-width, initial-scale=1.0' }
    = title
    = stylesheet_link_tag 'application'
    = javascript_include_tag 'vendor/modernizr'
    = csrf_meta_tags
  %body
    = yield
    = javascript_include_tag 'application'
HAML
create_file 'doc/wiki/Home.md', <<-MD
# Rails Application Development Wiki

## Table of contents

* [[Setup|Setup Instructions]]
* [[Services]]
* [[Testing]]
* [[Deployment]]
MD
create_file 'doc/wiki/Setup.md', <<-MD
# Setup instructions

Describe how the project should be set up, including system dependencies and
required configuration.
MD
create_file 'doc/wiki/Testing.md', <<-MD
# Testing

Describe how to run the test suite
MD
create_file 'doc/wiki/Services.md', <<-MD
# Services

Describe additional serivces (job queues, cache servers, search engines, etc.)
MD
create_file 'doc/wiki/Deployment.md', <<-MD
# Deployment

Describe how to the deploy the application
MD

role = ask('What role should be used for the database configuration?')
run 'cp config/database.yml config/database.yml.example'
gsub_file 'config/database.yml', /  username: .+$/, "  username: #{role}"
append_to_file '.gitignore', 'config/database.yml'

run 'bundle check && bundle install'
run 'bundle update'
run 'bundle exec guard init rspec'
run 'bundle exec guard init livereload'
gsub_file 'Guardfile', /guard :rspec do/, "guard :rspec, cmd: 'spring rspec' do"

rake 'db:create'

generate 'rspec:install'
generate 'simple_form:install'
generate 'devise:install'
generate 'pundit:install'
generate 'devise user'
generate 'kaminari:config'
generate 'foundation:install'

rake 'db:migrate'
rake 'db:test:prepare'

run 'spring binstub rspec'
run 'spring binstub rake'
run 'spring binstub rails'
run 'bundle binstubs guard'
run 'bundle binstubs thin'
run 'bundle binstubs foreman'
run 'bundle binstubs rubocop'
