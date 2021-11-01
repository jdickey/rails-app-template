# frozen_string_literal: true

# DRAFT Rails Application Template
# Copyright 2021, Jeff Dickey/Seven Sigma Agility
# Licensed for public use under the MIT License.
#
# This template sets up a newly-created Rails app, in conjunction with the
# associated `.railsrc` file. This (mostly; see below) automates processes that
# have been in use for a decade or so, over dozens of apps. Better late than
# never, yes? B-)
#
# Sample usage would look something like
# ```
#   rails new the_app -m ./template.rb
# ```
# where `the_app` would be replaced by the actual name of your new application.
#
# First, we set up our Gemfile. This is somewhat abbreviated from our standard
# since this whole script runs essentially as a hook within Rails' template
# processing, which has already created a Gemfile by the time we get here. It
# Would Be Very Nice if that was documented a bit more clearly in the Rails
# Guides, but oh well.
#
# This setup assumes `zsh`, `rbenv`, and `rbenv-gemset`. It further asdumes that
# it is being run from what will become the parent directory of the new app, in
# which exists a `.ruby-version` file, and possibly an `.rbenv-gemset` directory
# that will be **DELETED** if it exists.
################################################################################

# FIXME: Outdated, hardcoded Node packages are *evil*.

gem 'redis', '~> 4.0'
gem 'bcrypt', '~> 3.1.7'
gem "bundler-audit", "~> 0.9.0"
gem "dotenv-rails", "~> 2.7"
gem "dry-monads", "~> 1.4"
gem "ice_nine", "~> 0.11.2"
gem "slim-rails", "~> 3.3"
gem "foreman", "~> 0.87.2"
gem "sassc-rails", "~> 2.1"

gem "bundler", "~> 2.2"
gem "database_cleaner", "~> 2.0"
gem "pry-byebug", "~> 3.8"
gem "pry-doc", "~> 1.2"
gem "pry-rails", "~> 0.3.9"
# gem "stimulus_reflex", "~> 3.4"

gem "nokogiri", ">= 1.12.5"
gem "view_component", "~> 2.40", require: 'view_component/engine'

gem_group :development, :test do
  gem "flay", "~> 2.12"
  gem "flog", "~> 4.6"
  gem "inch", "~> 0.8.0"
  gem "reek", "~> 6.0"
  gem "rubocop-rails", "~> 2.12"
  gem "yard", "~> 0.9.26"

  gem "fabrication", "~> 2.22"
  gem "simplecov", "~> 0.21.2"
  gem "ffaker", "~> 2.19"
  gem "rspec-html-matchers", "~> 0.9.4"
  gem "html2slim", "~> 0.2.0"
end

gem_group :test do
  # These Gems are added by the Rails 6 installer. If using this script with an
  # earlier version of Rails, you may well need to uncomment these..
  # gem 'capybara', '>= 3.26'
  # gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  # gem 'webdrivers'
  gem "rspec-rails", "~> 5.0"
end

#
# Gemfile created; on to
# * initial setup of the `rbenv` gemset; and
# * running (what as far as we care is the first) `bundle install`.
#

run "cp ../.ruby-version ."
run 'rm -f .rbenv-gemset'

run "mkdir -p bin tmp/gemset"
run "rbenv gemset delete #{ENV['RBENV_VERSION']} ./tmp/gemset 2>&1 > /dev/null"
run "rbenv gemset create #{ENV['RBENV_VERSION']} ./tmp/gemset"
run 'rm -f .rbenv-gemset'
run "rbenv gemset init ./tmp/gemset"
# run "echo ./tmp/gemset > .rbenv-gemset"
run 'cd #{@app_name}; rbenv rehash; echo "Active gemsets: " `rbenv gemset active`'
run "bundle install"

#
# Make sure we've got all our binstubs set up so that Rails will simply use them
# (instead of complaining that they're set up for BUndler.)
#

run "bundle binstubs --all --force"
run 'rm -f bin/bundle'
run "(yes | rails app:update:bin)", capture: true
rails_command 'app:update:bin'
run 'bundle binstubs bundler'
git add: 'bin/bundle'

#
# Create the database role/user for the app.
#

run "createuser -dw #{@app_name}"

#
# Tell Rails to use the `fabrication` Gem fixture data. It's pretty cool that
# Rails/Thor has the `inject_data_file` method; this used to be the first of
# two steps performed manually by directly editing files.
#

inject_into_file "config/application.rb",
  after: "    config.generators.system_tests = nil\n" do <<-EOS

    config.generators do |gen|
      gen.test_framework      :rspec, fixture_replacement: :fabrication
      gen.fixture_replacement :fabrication, dir: "spec/fabricators"
    end
  EOS
end

#
# Fix the generated `Rails.root.join` call in the development environment, else
# Rubocop will kvetch about it whenever its Rake task is called, either directly
# or as part of the default processing. (See the Rake task setup below.)
#

gsub_file('config/environments/development.rb',
  "Rails.root.join('tmp', 'caching-dev.txt')",
  "Rails.root.join('tmp/caching-dev.txt')")

#
# Create the initial (empty) development and test databases.
#

rails_command "db:create"
rails_command "db:migrate"
rails_command "db:seed"

#
# Now is a good time to get RSpec set up
#

rails_command 'generate rspec:install'

#
# Create a Procfile for `foreman` to use to run multiple processes, including
# the web server running our app.
#

create_file "Procfile", <<-ENDIT
webpack: bin/webpack-dev-server
web:     bin/rails server -p 3000
ENDIT
# TBD: Find out why Foreman changes ports & we must explicitly specify 3000

run 'bin/foreman check'

#
# Set up Git and stage all existing files not specified in `.gitignore`. Note
# that we aren't committing yet; the idea is that we'll have one single commit
# after all steps in this generator script (and the surrounding Rails processing
# code) will have been completed.
#
# TBD: Figure out how to define an after-all-generator-steps-completed hook. Not
# just for this script; for the whole generator that this runs within.
#
run 'rm -rf .git'
git init: '-b main'
git add: '.'

insert_into_file 'spec/spec_helper.rb', before: 'RSpec.configure do |config|' do <<-EOS

require 'simplecov'

SimpleCov.start do
  coverage_dir './tmp/coverage'
  add_filter '/lib/tasks'
  add_filter '/spec'
  add_filter '/tmp'
end

  EOS
end
git add: 'spec/spec_helper.rb'

#
# Set up Webpacker.
# TBD: In future, we'll likely add Stimulus JS, but not at present.
#

rails_command 'dev:cache'
rails_command 'webpacker:install'
rails_command 'webpacker:check_binstubs'
git add: '.'

#
# We use Slim for view templates, not ERb as generated by default. Convert the
# app-wide base view template.
#

run 'erb2slim -d app/views/layouts/application.html.erb'
git add: 'app/views/layouts/'

#
# Add configuration files for Flay, Reek, and Rubocop
#

# Add .flayignore

create_file '.flayignore', <<-ENDIT
./spec/**/*.rb
./tmp/**/*
ENDIT
git add: '.flayignore'

# Add Reek config

create_file 'config.reek', <<-ENDIT
---

detectors:
  IrresponsibleModule:
    enabled: false
  MissingSafeMethod:
    enabled: false
  NestedIterators:
    max_allowed_nesting: 2
    ignore_iterators:
    - lambda
  UncommunicativeVariableName:
    exclude:
    - Conversagence::Application
  UnusedPrivateMethod:
    enabled: true
  UtilityFunction:
    public_methods_only: true
  LongParameterList:
    max_params: 4 # If it's good enough for Sandi, it's good enough for us
ENDIT
git add: 'config.reek'

# Add Rubocop config
create_file '.rubocop.yml', <<ENDIT
require:
  - rubocop-rails

AllCops:
  TargetRubyVersion: 2.6

Bundler/OrderedGems:
  Exclude:
    - 'Gemfile'

Metrics/BlockLength:
  Max: 300
  Include:
    - 'test/**/*.rb'

Metrics/ModuleLength:
  Max: 300
  Include:
    - 'test/**/*.rb'

# Style/AsciiComments:
#   Exclude:
#     - 'spec/web/views/home/index_spec.rb'

Style/CommentedKeyword:
  Enabled: false

# This silences 'Missing top-level class documentation comment.', which we
# particularly want to do on (initially-)generated files.
Style/Documentation:
  Enabled: false
  Include:
    - 'app/**/*.rb'
    - 'lib/**/*.rb'
    - 'test/**/*.rb'

###
### New cops added as of rubocop 0.85.1 and rubocop-rails 2.6.0

Layout/EmptyLinesAroundAttributeAccessor:
  Enabled: true

Layout/SpaceAroundMethodCallOperator:
  Enabled: true

Lint/DeprecatedOpenSSLConstant:
  Enabled: true

Lint/MixedRegexpCaptureTypes:
  Enabled: true

Lint/RaiseException:
  Enabled: true

Lint/StructNewOverride:
  Enabled: true

Style/ExponentialNotation:
  Enabled: true

Style/HashEachMethods:
  Enabled: true

Style/HashTransformKeys:
  Enabled: true

Style/HashTransformValues:
  Enabled: true

Style/RedundantRegexpCharacterClass:
  Enabled: true

Style/RedundantRegexpEscape:
  Enabled: true

Style/SlicingWithRange:
  Enabled: true
ENDIT
git add: '.rubocop.yml'

#
# Add Rake task definitions, and the default set and order of tasks to be run
# by `rake` when invoked without a task name.
#

## For Flay

create_file "lib/tasks/flay.rake", <<-ENDIT
# frozen_string_literal: true

require 'flay'
require 'flay_task'

FlayTask.new do |t|
  t.verbose = true
  t.dirs = %w[app config lib]
end
ENDIT
git add: 'lib/tasks/flay.rake'

## For Flog

create_file 'lib/tasks/flog.rake', <<-ENDIT
# frozen_string_literal: true

require 'flog'
require 'flog_task'

class FlogTask < Rake::TaskLib
  attr_accessor :methods_only
end

FlogTask.new do |t|
  t.verbose = true
  t.threshold = 200 # default is 200
  t.methods_only = true
  t.dirs = %w[app config lib] # Look, Ma; no specs! Run the tool manually every so often for those.
end
ENDIT
git add: 'lib/tasks/flog.rake'

## For Inch

create_file "lib/tasks/inch.rake", <<-ENDIT
# frozen_string_literal: true

require 'inch/rake'

Inch::Rake::Suggest.new do |t|
  t.args = ['--no-undocumented', '--pedantic']
end
ENDIT
git add: 'lib/tasks/inch.rake'

## For Reek

create_file "lib/tasks/reek.rake", <<-ENDIT
# frozen_string_literal: true

require 'reek/rake/task'

Reek::Rake::Task.new do |t|
  t.config_file = 'config.reek'
  t.source_files = '{app,config,lib}/**/*.rb'
  t.reek_opts = '--sort-by smelliness --no-progress  -s'
  # t.verbose = true
end
ENDIT
git add: 'lib/tasks/reek.rake'

## For Rubocop
create_file "lib/tasks/rubocop.rake", <<-ENDIT
# frozen_string_literal: true

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = [
    'app/**/*.rb',
    'config/**/*.rb',
    'lib/**/*.rb',
    'spec/**/*.rb'
  ]
  task.formatters = ['simple']
  task.fail_on_error = true
  task.requires << 'rubocop-rails'
  task.options << '--config=.rubocop.yml'
  task.options << '--display-cop-names'
end
ENDIT
git add: 'lib/tasks/rubocop.rake'

## For Bundler sub-tasks

create_file "lib/tasks/bundler-audit.rake", <<-ENDIT
# frozen_string_literal: true

namespace :bundler do
  desc 'Run bundler-audit, updating its database and then verbosely checking'

  task :audit do
    system('bundler-audit check -uv')
  end
end
ENDIT
git add: 'lib/tasks/bundler-audit.rake'

## Defaults
# frozen_string_literal: true

create_file "lib/tasks/defaults.rake", <<-ENDIT
# frozen_string_literal: true

default_tasks=%i[spec flog flay reek inch rubocop:auto_correct rubocop]
bundler_tasks=[]

if ENV['RAKE_BUNDLER'] || ENV['RAKE_BUNDLER_GRAPH']
  bundler_tasks = %i[bundler:audit bundler:dependencies:count]
  if ENV['RAKE_BUNDLER_GRAPH']
    bundler_tasks = %i[bundler:audit bundler:dependencies:graph bundler:dependencies:count]
  end
  default_tasks += bundler_tasks
end

# Rake::Task['default'].clear
task default: default_tasks

default_tasks = nil
bundler_tasks = nil
ENDIT
git add: 'lib/tasks/defaults.rake'

#
# Install TailwindCSS et al
#

run 'yarn add tailwindcss@npm:@tailwindcss/postcss7-compat postcss@^7 autoprefixer@^9'
git add: 'package.json yarn.lock'

insert_into_file 'postcss.config.js', after: '  plugins: [' do <<-EOS
    require('tailwindcss'),
  EOS
end
git add: 'postcss.config.js'

run 'npx tailwindcss init'
git add: 'tailwind.config.js'

insert_into_file 'app/javascript/packs/application.js', after: 'Turbolinks.start()' do <<-EOS

import "tailwindcss/tailwind.css"
  EOS
end
git add: 'app/javascript/packs/application.js'
gsub_file('app/views/layouts/application.html.slim', 'stylesheet_link_tag',
  'stylesheet_pack_tag')
git add: 'app/views/layouts/application.html.slim'

#
# Let's just make everything Rubocop-clean before we're done.
#

rails_command 'rubocop:auto_correct'
git add: 'app/ config/ spec/'
# run 'git add --force public/packs/manifest.json'

#
# NOTE: Not included here are things that might possibly vary between projects:
#
# 1. Authentication: Devise has come a *long* way since we first looked at it,
#    back in the Rails 3.2 days. It certainly now has very widespread use, but
#    doesn't look like it'g going to be bundled with Rails anytime soon.
# 2. Authorisation: There are probably more authorisation schemes in production
#    in Rails apps than there are Rails core team members. While there are a
#    half-dozen or so leaders of the pack, none has a decisive enough lead to
#    cast it in concrete here.
# 3. Service objects or analogues thereto. While we've used several bespoke
#    Interactor/Interaction Gems in the past, as of late 2021 we seem to be
#    gravitating towards POROS using dry-monads' 'do notation' for stepwise
#    execution and error handling.
# 4. Following on from the above, dry-rb is an extremely useful set of tools,
#    in spite of (or along with, depending on your view) being a gateway drug to
#    a decidedly Rails-independent yet -compatible way of doing things. Near-
#    future versions of this template will almost certainly include several of
#    these Gems.
#
# We'll run `hr` a couple of times so that it's visually apparent in the output
# from generating the app where the end of our template is.
#

# All files in the project should have been added to the git repo by now. Create
# a single commit

git commit: %Q{ -m 'Initial commit of new shop-standard-compliant app' }

run "hr"
run "hr"
