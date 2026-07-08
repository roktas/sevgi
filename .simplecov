# frozen_string_literal: true

root = File.expand_path(__dir__)
project = File.basename(Dir.pwd)
suite = ARGV.any? { |arg| arg.end_with?("integration_test.rb") } ? "integration" : "test"

SimpleCov.root(root)
SimpleCov.coverage_dir(File.join(root, ".cache/ruby/coverage"))
SimpleCov.command_name("#{project}:#{suite}")

SimpleCov.start do
  enable_coverage(:branch)
  track_files("{derender,function,geometry,graphics,showcase,standard,sundries,toplevel}/lib/**/*.rb")

  add_filter("/test/")

  add_group("Derender", "derender/lib")
  add_group("Function", "function/lib")
  add_group("Geometry", "geometry/lib")
  add_group("Graphics", "graphics/lib")
  add_group("Showcase", "showcase/lib")
  add_group("Standard", "standard/lib")
  add_group("Sundries", "sundries/lib")
  add_group("Toplevel", "toplevel/lib")
end
