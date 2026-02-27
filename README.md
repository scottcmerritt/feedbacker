# Feedbacker
Short description and motivation.

## Developer notes

1. Write code
2. 
    Add to github (the project gem is linked to the github repository)
    git add .
    git commit -am "message here"
    git push -u origin main

    So you only need to push your source (including feedbacker.gemspec). No .gem file has to be in the repo or built beforehand.
    When you do need to build the gem:
    Publishing to RubyGems.org (e.g. gem build feedbacker.gemspec then gem push)
    Installing from a local .gem file
    Using a private gem server that expects uploaded .gem files
    Practical note: Many gems add *.gem to .gitignore so the built artifact isn’t committed. For git-based installs, that’s the right approach.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'feedbacker'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install feedbacker
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
