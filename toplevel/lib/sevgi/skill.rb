# frozen_string_literal: true

require "rubygems"
require "sevgi"

module Sevgi
  # Locates the agent skill packaged for the installed Sevgi version.
  # @api private
  module Skill
    extend self

    Error = Class.new(::Sevgi::Error)

    def path
      spec = ::Gem::Specification.find_by_name("sevgi-appendix", "= #{::Sevgi::VERSION}")
      packaged = packaged_path(spec)
      # Package managers may replace a versioned gem path with their stable prefix.
      path = ::File.expand_path(ENV.fetch("SEVGI_SKILL", packaged))

      Error.("Sevgi skill is unavailable at #{path}.") unless ::File.file?(::File.join(path, "SKILL.md"))

      path
    rescue ::Gem::MissingSpecError
      Error.("sevgi-appendix #{::Sevgi::VERSION} is not installed.")
    end

    private

    def packaged_path(spec)
      relative = spec.metadata["sevgi_skill_path"]
      root = ::File.expand_path(spec.full_gem_path)
      path = ::File.expand_path(relative, root) if relative.is_a?(String) && !relative.empty?
      inside = path&.start_with?("#{root}#{::File::SEPARATOR}")

      Error.("sevgi-appendix #{::Sevgi::VERSION} does not declare a valid skill path.") unless inside

      path
    end
  end

  private_constant :Skill
end
