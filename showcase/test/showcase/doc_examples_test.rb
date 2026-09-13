# frozen_string_literal: true

require_relative "../test_helper"

require "tmpdir"

module DocumentationExamples
  CONTENT = File.expand_path("../../doc/content", __dir__)
  ENTRIES = Dir[File.join(CONTENT, "*.md")]
    .flat_map do |file|
      File.read(file).scan(/^```ruby\n(.*?)^```$/m).each_with_index.map do |(code), index|
        [file, index + 1, code]
      end
    end
    .freeze
end

describe "documentation examples" do
  def prepare(directory)
    File.write(
      File.join(directory, "badge.svg"),
      "<svg xmlns=\"http://www.w3.org/2000/svg\"><g id=\"group\"><rect id=\"mark\" width=\"4\" height=\"2\"/></g></svg>"
    )
    File.write(
      File.join(directory, "card.sevgi"),
      <<~RUBY
        raise "Wrong arguments" unless ARGA == ["front"] && ARGH == {theme: :dark}
        SVG(width: 85, height: 55) { rect width: 85, height: 55 }.Save "card.svg"
      RUBY
    )
  end

  def execute(file, code)
    if code.include?("sevgi/binaries/rake")
      require "rake"
      require "sevgi/binaries/rake"

      previous = Rake.application
      begin
        Rake.application = Rake::Application.new
        Object.new.extend(Rake::DSL).extend(FileUtils).instance_eval(code, file, 1)
        Rake::Task["card.svg"].invoke
        assert_path_exists("card.svg")
      ensure
        Rake.application = previous
      end
    elsif code.match?(%r{^require "sevgi(?:/graphics)?"$})
      Object.new.instance_eval(code, file, 1)
    else
      source = File.join(Dir.pwd, File.basename(file))
      instance_eval(code, source, 1)
    end
  end

  it "finds examples" do
    assert_operator(DocumentationExamples::ENTRIES.size, :>=, 20)
  end

  it "saves a standalone drawing from the README and Start examples" do
    readme = File.expand_path("../../../README.md", __dir__)
    examples = [
      [
        readme,
        File.read(readme).scan(/^```ruby\n(.*?)^```$/m).map(&:first).find { it.include?("drawing.Save \"badge.svg\"") }
      ],
      DocumentationExamples::ENTRIES
        .find { |file, _, code| File.basename(file) == "start.md" && code.include?("end.Save \"badge.svg\"") }
        .values_at(0, 2)
    ]
    examples.each do |file, code|
      Dir.mktmpdir do |directory|
        Dir.chdir(directory) do
          execute(file, code)
          xml = Nokogiri::XML(File.read("badge.svg"), &:strict)
          assert_equal("http://www.w3.org/2000/svg", xml.root.namespace.href)
          assert_equal(%w[120 60], %w[width height].map { xml.root[it] })
          circle = xml.at_xpath("//*[local-name()='circle']")
          assert_equal(%w[60 30 16], %w[cx cy r].map { circle[it] })
        end
      end
    end
  end

  DocumentationExamples::ENTRIES.each do |file, index, code|
    it "runs #{File.basename(file)} example #{index}" do
      Dir.mktmpdir("sevgi-doc-") do |directory|
        prepare(directory)
        Dir.chdir(directory) { capture_io { execute(file, code) } }
      end
    end
  end
end
