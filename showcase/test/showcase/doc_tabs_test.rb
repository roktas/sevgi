# frozen_string_literal: true

require "json"
require "open3"

require_relative "../test_helper"

module Sevgi
  module Showcase
    class DocTabsTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)

      def test_normalize_svg_converts_absolute_units
        result = run_tabs_fixture("absolute")

        [
          "0 0 96 96",
          result.fetch("mixed"),
          "0 0 37.795276 18.897638",
          result.fetch("same"),
          "0 0 150 80",
          result.fetch("exponent")
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_normalize_svg_leaves_unsafe_dimensions_unchanged
        result = run_tabs_fixture("fallbacks")

        [
          nil,
          result.fetch("zero"),
          nil,
          result.fetch("negative"),
          nil,
          result.fetch("percent"),
          nil,
          result.fetch("missing"),
          "0 0 7 9",
          result.fetch("existing")
        ].each_slice(2) { |expected, actual| assert_value(expected, actual) }
      end

      private

      def assert_value(expected, actual)
        expected.nil? ? assert_nil(actual) : assert_equal(expected, actual)
      end

      def run_tabs_fixture(fixture)
        stdout, stderr, status = Open3.capture3("node", "-e", node_script, tabs_js, fixture)
        skip("node unavailable") if status.exitstatus == 127

        assert(status.success?, stderr)
        JSON.parse(stdout)
      rescue Errno::ENOENT
        skip("node unavailable")
      end

      def node_script
        <<~JS
          const fs = require('fs');
          const vm = require('vm');
          const source = fs.readFileSync(process.argv[1], 'utf8').replace(
            /\\}\\)\\(\\);\\s*$/,
            'window.__sevgiTabs = { normalizeSvg: normalizeSvg }; })();'
          );
          const context = {
            window: {
              matchMedia: function() {
                return { matches: false, addEventListener: function() {}, addListener: function() {} };
              }
            },
            document: {
              documentElement: { getAttribute: function() { return null; } },
              readyState: 'loading',
              addEventListener: function() {},
              querySelectorAll: function() { return []; }
            },
            MutationObserver: function() {
              this.observe = function() {};
            }
          };
          context.window.document = context.document;
          vm.createContext(context);
          vm.runInContext(source, context);

          function svg(attrs) {
            return {
              attrs: Object.assign({}, attrs),
              getAttribute: function(name) {
                return Object.prototype.hasOwnProperty.call(this.attrs, name) ? this.attrs[name] : null;
              },
              setAttribute: function(name, value) {
                this.attrs[name] = String(value);
              }
            };
          }

          function normalize(attrs) {
            const node = svg(attrs);
            context.window.__sevgiTabs.normalizeSvg({
              querySelector: function(selector) {
                return selector === 'svg' ? node : null;
              }
            });
            return node.attrs.viewBox || null;
          }

          const fixtures = {
            absolute: {
              mixed: normalize({ width: '1in', height: '25.4mm' }),
              same: normalize({ width: '10mm', height: '5mm' }),
              exponent: normalize({ width: '1.5e2px', height: '.5e1pc' })
            },
            fallbacks: {
              zero: normalize({ width: '0', height: '10' }),
              negative: normalize({ width: '-1', height: '10' }),
              percent: normalize({ width: '100%', height: '10' }),
              missing: normalize({ width: '10' }),
              existing: normalize({ width: '1in', height: '25.4mm', viewBox: '0 0 7 9' })
            }
          };

          process.stdout.write(JSON.stringify(fixtures[process.argv[2]]));
        JS
      end

      def tabs_js = File.join(ROOT, "doc/static/js/tabs.js")
    end
  end
end
