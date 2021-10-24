# rails-app-template
## Attempting Automation of Rails App Generation with .railsrc and App Generator

After too many years doing this, never mind how many, I'm attempting to automate the generation of Rails apps using a
`.railsrc` file and an app-generation template. The `.railsrc` file, largely cribbed from numerous others, appears to work
splendidly.

The template file, which should automate setup of the newly-created app to current shop standards, is being developed incrementally; increments largely separated by *the next wall I hit*. The template-and-`.railsrc` setup presently works, if *works* can be defined as "generates a shop-standard-compliant app, but the process automation is as yet incomplete". The as-yet-incomplete bits (described in [Problem Statement](#problem-statement), below) are hopefully due more to my imperfect understanding of all things Thor-and-Rails-app-generator rather than unsupported features of the underlying platform. 

## Possibly Relevant Background Items

1. Ruby is installed by way of [`rbenv`](https://github.com/rbenv/rbenv#readme), which we have used for *years* without known issues. We are presently on Ruby 3.0.2p107.
2. I'm attempting to continue our long-time shop-standard usage of [`rbenv-gemsets`](https://github.com/jf/rbenv-gemset#readme), which has hitherto (before attempted use of an app generator) saved our proverbial bacon often enough that I still have *some* hair. It supports our experimentation and evolution of candidate Gems for use, without polluting the system Gem repository.

## Problem Statement

When I generate a new app using the template, everything appears to work fine *as far as the template script running within the generator is concerned.* However, after the new-app generator finishes, the new-app generator resumes processing, it modifies some *two dozen* files; e.g., by adding several new Railtie includes to `config/application.rb`. These changes, of course, are not staged for commit and thus would not be committed using a `git commit` before a `git add`.

What I'd really like to have is a hook I can use (by defining a block to be executed after the *entire* generator has successfully completed, in the style of Thor's [`inject_into_file`](https://github.com/rails/thor/blob/efe79b599eb401d36265ed4a8b48fb60f42a06a4/lib/thor/actions/inject_into_file.rb). This would eliminate the
need for any manual processing between invocation of `rails new` and the conclusion of the first Git commit.

It Would Be Very Nice If&reg; there was documentation somewhere on exactly *how* those files were modified, including which parameters to `eails new` initiated each particular change.

And I *still* haven't figured out why the bundled Gems are being installed in the `rbenv` Gem repository rather than my gemset, as occurs when I perform the generator-script steps manually?

Help?
