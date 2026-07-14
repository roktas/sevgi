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
  end

  def execute(file, code)
    if File.basename(file) == "script-mode.md" && code.include?("sevgi/binaries/rake")
      require "rake"
      require "sevgi/binaries/rake"

      Object.new.extend(Rake::DSL).extend(FileUtils).instance_eval(code, file, 1)
    elsif File.basename(file) == "library-mode.md"
      Object.new.instance_eval(code, file, 1)
    else
      source = File.join(Dir.pwd, File.basename(file))
      instance_eval(code, source, 1)
    end
  end

  it "finds examples" do
    assert_operator(DocumentationExamples::ENTRIES.size, :>=, 20)
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
