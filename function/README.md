# Sevgi Function

Sevgi Function contains the supported `Sevgi::F` toolbox shared by Sevgi components and advanced extensions. It is not
a general-purpose utility library. Nested helper modules organize the facade implementation and are not consumer
mixins.

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
Sevgi::F.with_precision(12) do
  Sevgi::F.eq?(0.1 + 0.2, 0.3) # => true
end
```

The facade also provides `.sevgi` file discovery, generated-file output, argv-safe child processes, naming helpers,
and terminal status output. Use the linked API documentation for exact results and failure contracts.

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies the current Ruby 3.4 release and the development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: <https://sevgi.roktas.dev>
- API documentation: <https://www.rubydoc.info/gems/sevgi-function>
- Source: <https://github.com/roktas/sevgi/tree/main/function>
- Changelog: <https://github.com/roktas/sevgi/blob/main/CHANGELOG.md>
