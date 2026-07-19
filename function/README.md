# Sevgi Function

Sevgi Function contains the supported `Sevgi::F` toolbox shared by Sevgi components and advanced extensions. It is not
intended as a general-purpose utility library; nested helper modules organize the facade implementation and are not
consumer mixins.

## Install

```sh
gem install sevgi-function
```

## Require

```ruby
require "sevgi/function"
```

## Example

```ruby
Sevgi::F.eq?(0.1 + 0.2, 0.3, precision: 12)
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-function>
- Source: <https://github.com/roktas/sevgi/tree/main/function>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
