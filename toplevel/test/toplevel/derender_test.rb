# frozen_string_literal: true

require "open3"
require "nokogiri"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  class ToplevelDerenderTest < Minitest::Test
    def test_decompile_delegates_to_file_api
      calls = []
      node = Object.new

      ::Sevgi::Derender.stub(
        :decompile_file,
        -> (file, id:) {
          calls << [file, id]
          node
        }
      ) do
        assert_same(node, receiver.Decompile("drawing", "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    def test_decompile_accepts_missing_id
      calls = []
      node = Object.new

      ::Sevgi::Derender.stub(
        :decompile_file,
        -> (file, id:) {
          calls << [file, id]
          node
        }
      ) do
        assert_same(node, receiver.Decompile("drawing"))
      end

      assert_equal([["drawing", nil]], calls)
    end

    def test_derender_delegates_to_file_api
      calls = []

      ::Sevgi::Derender.stub(
        :derender_file,
        -> (file, id:) {
          calls << [file, id]
          "SVG"
        }
      ) do
        assert_equal("SVG", receiver.Derender("drawing", "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    def test_derender_accepts_missing_id
      calls = []

      ::Sevgi::Derender.stub(
        :derender_file,
        -> (file, id:) {
          calls << [file, id]
          "SVG"
        }
      ) do
        assert_equal("SVG", receiver.Derender("drawing"))
      end

      assert_equal([["drawing", nil]], calls)
    end

    def test_derender_source_treats_ruby_names_as_elements
      Dir.mktmpdir do |dir|
        marker = ::File.join(dir, "system-called")
        xml = <<~SVG
          <svg>
            <system>printf derender-system &gt; #{marker}</system>
            <send>object_id</send>
            <exit>0</exit>
            <raise>derender-raise</raise>
            <object_id>object-id</object_id>
            <font-face/>
            <color-profile/>
            <class/>
            <custom_name/>
          </svg>
        SVG
        file = ::File.join(dir, "generated.sevgi")
        ::File.write(file, "#{Derender.derender(xml)}.Out(validate: false)\n")

        out, err, status = run_sevgi(file)

        assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
        refute_path_exists(marker)
        root = ::Nokogiri::XML(out, &:strict).root
        expected = %w[system send exit raise object_id font-face color-profile class custom_name]

        assert_equal(expected, root.element_children.map(&:name))
        system = root.element_children.find { it.name == "system" }
        assert_equal("printf derender-system > #{marker}", system.text)
      end
    end

    private

    def run_sevgi(file)
      lib = ::File.expand_path("../../lib", __dir__)
      bin = ::File.expand_path("../../bin/sevgi", __dir__)
      rubylib = [lib, ENV.fetch("RUBYLIB", nil)].compact.join(::File::PATH_SEPARATOR)

      ::Open3.capture3({"RUBYLIB" => rubylib, "SEVGI_VOMIT" => nil}, ::RbConfig.ruby, bin, file)
    end

    def receiver
      Class
        .new do
          include(::Sevgi)
        end
        .new
    end
  end
end
