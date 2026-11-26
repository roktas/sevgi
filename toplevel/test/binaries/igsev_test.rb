# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

require "sevgi/binaries/igsev"

module Sevgi
  module Binaries
    class IgsevTest < Minitest::Test
      def test_executable_round_trips_svg
        source = <<~SVG
          <?xml version="1.0" standalone="yes"?>
          <!--license-->
          <svg xmlns="http://www.w3.org/2000/svg" width="10"><circle r="4"/></svg>
        SVG

        with_svg(source) do |file|
          out, err, status = run_igsev(file)

          assert_predicate(status, :success?)
          assert_equal(
            <<~SVG,
              <?xml version="1.0" standalone="yes"?>
              <!--license-->
              <svg xmlns="http://www.w3.org/2000/svg" width="10">
                <circle r="4"/>
              </svg>
            SVG
            out
          )
          assert_empty(err)
        end
      end

      def test_executable_omits_repeated_attributes
        source = "<svg xmlns=\"http://www.w3.org/2000/svg\" id=\"root\"><rect id=\"mark\" style=\"fill: red\"/></svg>"
        with_svg(source) do |file|
          out, err, status = run_igsev("--omit", "id", "--omit", "style", file)

          assert_predicate(status, :success?)
          refute_match(/\bid=/, out)
          refute_match(/\bstyle=/, out)
          assert_empty(err)
        end
      end

      def test_executable_transcodes_declared_encodings_to_utf8
        [
          ["encoding=\"ISO-8859-1\"", "café", "ISO-8859-1"],
          ["encoding = 'ISO-8859-1'", "caf&#233;", "US-ASCII"],
          ["encoding=\"UTF-16\"", "café", "UTF-16"]
        ].each do |declaration, text, encoding|
          source = "<?xml version=\"1.0\" #{declaration} standalone=\"yes\"?><svg><text>#{text}</text></svg>".encode(
            encoding
          )

          with_svg(source) do |file|
            [run_igsev(file), run_igsev(stdin_data: source)].each do |out, err, status|
              assert_predicate(status, :success?, err)
              assert_empty(err)
              assert_includes(out, "encoding=\"UTF-8\"")
              assert_includes(out, "standalone=\"yes\"")
              assert_equal("café", Nokogiri::XML(out.b, &:strict).at_css("text").text)
            end
          end
        end
      end

      def test_executable_loads_required_library
        with_svg("<svg xmlns=\"http://www.w3.org/2000/svg\"><circle r=\"4\"/></svg>") do |file|
          first = ::File.join(::File.dirname(file), "first.rb")
          second = ::File.join(::File.dirname(file), "second.rb")
          ::File.write(first, "warn \"first\"")
          ::File.write(second, "warn \"second\"")

          argv = ["--require", first, "-r", second, file]
          snapshot = argv.dup
          _out, _err = capture_io { ::Sevgi.const_get(:Binaries, false)::Igsev.(argv) }
          assert_equal(snapshot, argv)

          out, err, status = run_igsev("--require", first, "-r", second, file)

          assert_predicate(status, :success?)
          assert_match(%r{<circle r="4"/>}, out)
          assert_equal("first\nsecond\n", err)
        end
      end

      def test_executable_accepts_dash_prefixed_file_after_separator
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "-drawing.svg"), "<svg xmlns=\"http://www.w3.org/2000/svg\"/>")

          out, err, status = run_igsev("--", "-drawing.svg", chdir: dir)

          assert_predicate(status, :success?)
          assert_match(/<svg xmlns=/, out)
          assert_empty(err)
        end
      end

      def test_executable_reads_stdin_when_file_is_omitted_or_dash
        source = "<svg xmlns=\"http://www.w3.org/2000/svg\"><circle r=\"4\"/></svg>"

        [[], ["-"]].each do |args|
          out, err, status = run_igsev(*args, stdin_data: source)

          assert_predicate(status, :success?)
          assert_match(%r{<circle r="4"/>}, out)
          assert_empty(err)
        end
      end

      def test_executable_preserves_text_and_attribute_whitespace
        source = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg">
            <text xml:space="preserve" data-note="A&#9;B&#10;C&#13;D"><tspan>A</tspan><tspan>B</tspan></text>
            <text xml:space="preserve"><tspan>A&#13;B</tspan></text>
          </svg>
        SVG

        out, err, status = run_igsev("-", stdin_data: source)
        assert(status.success?, err)
        target = SVG()
        SVG.EvaluateChildren(source, target)
        [out, target.call].each do |rendered|
          text, cr = Nokogiri::XML(rendered, &:strict).xpath("//svg:text", "svg" => "http://www.w3.org/2000/svg").to_a
          assert_equal("AB", text.content)
          assert_equal("A\tB\nC\rD", text["data-note"])
          assert_equal("A\rB", cr.content)
        end
      end

      def test_executable_checks_svg_descendants_of_foreign_objects
        source = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg">
            <foreignObject>
              <div xmlns="http://www.w3.org/1999/xhtml">Note</div>
              <word xmlns="">Plain</word>
              <svg><rect width="1"/></svg>
            </foreignObject>
          </svg>
        SVG
        out, err, status = run_igsev("-", stdin_data: source)
        assert(status.success?, err)
        children = Nokogiri::XML(out, &:strict).at_css("foreignObject").element_children
        assert_equal(
          ["http://www.w3.org/1999/xhtml", nil, "http://www.w3.org/2000/svg"],
          children.map { it.namespace&.href }
        )

        out, err, status = run_igsev("-", stdin_data: source.sub("width=\"1\"", "unknown=\"1\""))
        refute(status.success?)
        assert_empty(out)
        assert_match(/rect.*unknown/, err)
      end

      def test_executable_rejects_invalid_argv_grammar
        [
          [["--unknown"], /Not a valid option: --unknown/],
          [["-r"], /Option requires a library: -r/],
          [["--omit"], /No attribute given for --omit/],
          [%w[first.svg second.svg], /Unexpected argument: second\.svg/]
        ].each do |args, message|
          out, err, status = run_igsev(*args)

          assert_equal(1, status.exitstatus)
          assert_empty(out)
          assert_match(message, err)
          assert_match(/Usage: igsev \[options\.\.\.\] \[--\] \[SVG file\|-\]/, err)
        end
      end

      def test_executable_reports_fragment_input
        out, err, status = run_igsev("-", stdin_data: "<g/>")

        refute(status.success?)
        assert_empty(out)
        assert_includes(err, "igsev requires an SVG document root")
      end

      def test_prefixed_document_keeps_the_root_and_unqualified_children
        body = <<~SVG
          <v:svg xmlns:v="http://www.w3.org/2000/svg">
            <v:foreignObject><label>Plain</label><style>p { color: red; }</style></v:foreignObject>
          </v:svg>
        SVG
        out, err, status = run_igsev("-", stdin_data: "<!--license-->\n#{body}")
        assert(status.success?, err)
        assert_includes(out, "<!--license-->")
        target = SVG()
        imported = SVG.Evaluate(body, target)
        [out, imported.call].each do |rendered|
          root = Nokogiri::XML(rendered, &:strict).root
          assert_equal("v", root.namespace.prefix)
          assert_equal("http://www.w3.org/2000/svg", root.namespace.href)
          label, style = root.element_children.first.element_children.to_a
          assert_nil(label.namespace)
          assert_equal("Plain", label.text)
          assert_equal("p { color: red; }", style.text)
        end
      end

      def test_executable_reports_and_exposes_conversion_errors
        out, err, normal = run_igsev("missing.svg")
        raw_out, raw_err, raw = run_igsev("-x", "missing.svg")

        assert_equal(1, normal.exitstatus)
        assert_empty(out)
        assert_match(/File not found/, err)
        refute_match(/Traceback/, err)

        assert_equal(1, raw.exitstatus)
        assert_empty(raw_out)
        assert_match(/Sevgi::ArgumentError/, raw_err)
      end

      private

      def run_igsev(*args, chdir: nil, stdin_data: "")
        lib = ::File.expand_path("../../lib", __dir__)
        bin = ::File.expand_path("../../bin/igsev", __dir__)
        rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)
        options = chdir ? {chdir:} : {}

        ::Open3.capture3(
          {"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil},
          ::RbConfig.ruby,
          bin,
          *args,
          stdin_data:,
          **options
        )
      end

      def with_svg(source)
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "drawing.svg")
          ::File.write(file, source)
          yield(file)
        end
      end
    end
  end
end
