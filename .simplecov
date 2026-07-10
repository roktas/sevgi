# frozen_string_literal: true

require "simplecov_json_formatter"

root = File.expand_path(__dir__)
project = File.basename(Dir.pwd)
suite = ARGV.any? { |arg| arg.end_with?("integration_test.rb") } ? "integration" : "test"
components = %w[
  derender
  function
  geometry
  graphics
  showcase
  standard
  sundries
  toplevel
].freeze
tracked_glob = File.join(root, "{#{components.join(",")}}/lib/**/*.rb")
tracked_files = Dir[tracked_glob].map { |file| File.expand_path(file) }.sort

SimpleCov.root(root)
SimpleCov.coverage_dir(File.join(root, ".cache/ruby/coverage"))
SimpleCov.command_name("#{project}:#{suite}")
SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter]
SimpleCov.at_exit do
  result = SimpleCov.result
  missing = tracked_files - result.files.map(&:filename)
  raise("Coverage result is missing tracked files:\n#{missing.join("\n")}") unless missing.empty?

  result.format!
end

SimpleCov.start do
  enable_coverage(:branch)
  track_files(tracked_glob)

  add_filter("/test/")

  add_group("Derender", File.join(root, "derender/lib"))
  add_group("Function", File.join(root, "function/lib"))
  add_group("Geometry", File.join(root, "geometry/lib"))
  add_group("Graphics", File.join(root, "graphics/lib"))
  add_group("Showcase", File.join(root, "showcase/lib"))
  add_group("Standard", File.join(root, "standard/lib"))
  add_group("Sundries", File.join(root, "sundries/lib"))
  add_group("Toplevel", File.join(root, "toplevel/lib"))
end
