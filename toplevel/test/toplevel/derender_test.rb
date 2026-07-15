# frozen_string_literal: true

require "open3"
require "nokogiri"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  class ToplevelDerenderTest < Minitest::Test
    def test_decompile_delegates_to_content_api
      calls = []
      node = Object.new

      ::Sevgi::Derender.stub(
        :decompile,
        -> (content, id:) {
          calls << [content, id]
          node
        }
      ) do
        assert_same(node, receiver.Decompile("<svg/>", id: "Root"))
      end

      assert_equal([["<svg/>", "Root"]], calls)
    end

    def test_decompile_file_delegates_to_file_api
      calls = []
      node = Object.new

      ::Sevgi::Derender.stub(
        :decompile_file,
        -> (file, id:) {
          calls << [file, id]
          node
        }
      ) do
        assert_same(node, receiver.DecompileFile("drawing", id: "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    def test_derender_delegates_to_content_api
      calls = []

      ::Sevgi::Derender.stub(
        :derender,
        -> (content, id:) {
          calls << [content, id]
          "SVG"
        }
      ) do
        assert_equal("SVG", receiver.Derender("<svg/>", id: "Root"))
      end

      assert_equal([["<svg/>", "Root"]], calls)
    end

    def test_derender_file_delegates_to_file_api
      calls = []

      ::Sevgi::Derender.stub(
        :derender_file,
        -> (file, id:) {
          calls << [file, id]
          "SVG"
        }
      ) do
        assert_equal("SVG", receiver.DerenderFile("drawing", id: "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    def test_evaluate_delegates_to_content_api
      calls = []
      element = Object.new
      result = Object.new

      ::Sevgi::Derender.stub(
        :evaluate,
        -> (content, target, id:) {
          calls << [content, target, id]
          result
        }
      ) do
        assert_same(result, receiver.Evaluate("<svg/>", element, id: "Root"))
      end

      assert_equal([["<svg/>", element, "Root"]], calls)
    end

    def test_evaluate_file_delegates_to_file_api
      calls = []
      element = Object.new
      result = Object.new

      ::Sevgi::Derender.stub(
        :evaluate_file,
        -> (file, target, id:) {
          calls << [file, target, id]
          result
        }
      ) do
        assert_same(result, receiver.EvaluateFile("drawing", element, id: "Root"))
      end

      assert_equal([["drawing", element, "Root"]], calls)
    end

    def test_evaluate_children_delegates_to_content_api
      calls = []
      children = [].freeze
      element = Object.new

      ::Sevgi::Derender.stub(
        :evaluate_children,
        -> (content, target, id:) {
          calls << [content, target, id]
          children
        }
      ) do
        assert_same(children, receiver.EvaluateChildren("<svg/>", element, id: "Root"))
      end

      assert_equal([["<svg/>", element, "Root"]], calls)
    end

    def test_evaluate_children_file_delegates
      calls = []
      children = [].freeze
      element = Object.new

      ::Sevgi::Derender.stub(
        :evaluate_children_file,
        -> (file, target, id:) {
          calls << [file, target, id]
          children
        }
      ) do
        assert_same(children, receiver.EvaluateChildrenFile("drawing", element, id: "Root"))
      end

      assert_equal([["drawing", element, "Root"]], calls)
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
