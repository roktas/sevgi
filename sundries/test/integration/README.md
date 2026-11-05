# Mainz export integration

`mainz.rb` exports four independent Graphics Imprint declarations concurrently through Sundries and the native Mainz CLI.
It checks renderer identity, controls, profiles, page metadata, dimensions, QPDF structure, and Mainz validation.
It also exports a metadata-only page with a PNG preview.
Prepared export must not load the ordinary Cairo, RSVG2, or HexaPDF export path.
Generated PDFs stay in the repository's ignored `.local/mainz/` directory.

Build the sibling Mainz checkout's native preset first, then run from the Sevgi root:

```sh
direnv exec . env PATH="$PWD/../mainz/.local/var/cpp/build/native:$PATH" bundle exec ./sundries/test/integration/mainz.rb
```

The component unit tests run with `bundle exec rake sundries:test graphics:test`.
