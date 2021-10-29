# rails-app-template
## Attempting Automation of Rails App Generation with .railsrc and App Generator

After too many years doing this, never mind how many, I'm attempting to automate the
generation of Rails apps using a `.railsrc` file and an app-generation template. The `.railsrc` file, largely cribbed from numerous others, appears to work splendidly,
albeit with a couple of wrinkles.

The template file, which should automate setup of the newly-created app to current
shop standards, was developed incrementally; increments largely separated by *the next wall I hit*. The template-and-`.railsrc` setup presently generates a
shop-standard-compliant app, creates a Git repo within the app folder, and creates
a single commit for the generated app. 

## Possibly Relevant Background Items

1. Ruby is installed by way of [`rbenv`](https://github.com/rbenv/rbenv#readme), which we have used for *years* without known issues. We are presently on Ruby 3.0.2p107.
2. I'm attempting to continue our long-time shop-standard usage of [`rbenv-gemsets`](https://github.com/jf/rbenv-gemset#readme), which has hitherto (before attempted use of an app generator) saved our proverbial bacon often enough that I still have *some* hair. It supports our experimentation and evolution of candidate Gems for use, without polluting the system Gem repository.

## FIXMEs

I *still* haven't figured out why the bundled Gems are being installed in the
`rbenv` Gem repository rather than my gemset, as occurs when I perform the
generator-script steps manually. As noted above, this adds the Gens to the Ruby-wide
Gem store, possibly breaking other projects. These *should* be stored in the Gemset
created earlier in the script (see [the docs](https://github.com/jf/rbenv-gemset#usage) for usage details).

When running the app generator, the last command run (by the base generator) is
`bundle binstubs bundler`. It produces the following output:

```
Skipped bundle since it already exists.
If you want to overwrite skipped stubs, use --force.
```

Removing `bin/bundler` immediately after our script runs `bundle binstubs --all
--force` removes the reported error, and no additional steps are run by the base
generator, so that appears to be the quick-and-dirty fix going forward. 🤮

If anyone has any better ideas, *please* open a PR or, at least, add a comment to
the template script.

## Standard README Items

### Ruby and Rails Versions

This was developed using CRuby 3.0.2 for Rails 6.1.4.1. It is *likely* to work with
earlier releases of Rails 6 (and possibly Rails 5), using Ruby versions appropriate for that version of Rails.

### System Dependencies

This generator script assumes [`rbenv`](https://github.com/rbenv/rbenv) and its extension [`rbenv-gemset`](https://github.com/jf/rbenv-gemset) are installed. If you are in a use relationship with `rvm` or similarly eldritch Ruby version manager, you will need to make appropriate changes to [`template.rb`](https://github.com/jdickey/rails-app-template/template.rb) on your own.

The new app, as specified in the `.railsrc` file, uses PostgreSQL for its database. Use of other Rails-supported databases (eg, MySQL) should be a drop-in replacement (in `.railsrc`), but has not been tested and is not supported.

### Configuration

The options supplied to the `rails new` command are listed in the [`.railsrc`](https://github.com/jdickey/rails-app-template/.railsrc) file in this repository.
Tinkering with those settings may be Useful but is not explicitly supported here.

### Database creation and initialisation

The development and test databases for the generated app are created using the Rails-standard `rails db:create db:migrate db:seed` cycle, even though no seed data is initially used.

### Database deletion

Removing the databases can be done in one of two ways:

1. Within the app top-level directory, run `bin/rails db:drop`; or
2. Outside the application directory (whether or not it exists at the time), running `dropdb APP_development; dropdb APP_test` (under PostgreSQL), where `APP` is the name of the app as supplied to `rails new`.

### Test suite

The generated app uses RSpec as its test runner, with specs in the `spec` directory.

To run the test suite, run `bin/rspec spec`. This will run all specs (unless [otherwise configured](https://relishapp.com/rspec/rspec-core/v/2-6/docs/filtering/inclusion-filters)).

Running `bin/rspec` with no arguments will first run all tests (but see above paragraph), and then run the static-analysis tools `flog`, `flay`, `reek`, `inch`, and `rubocop`.

### Further Instructions

You may well not wish to clone this repo, unless you're planning on filing an issue
and/or PR. To copy the `template.rb` and `.railsrc` files independently, you can use
`curl`:

```
curl --silent --ignore-content-lengt https://raw.githubusercontent.com/jdickey/rails-app-template/master/template.rb > template.rb
curl --silent --ignore-content-lengt https://raw.githubusercontent.com/jdickey/rails-app-template/master/.railsrc > $HOME/.railsrc
```

Note that this will overwrite any existing file; beware especially if you have an existing `~/.railsrc` that you wish to preserve.

## Copyright and License

These files are Copyright &copy;2021 by Jeff Dickey and Seven Sigma Agility, and licensed under the MIT License.
