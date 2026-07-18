# frozen_string_literal: true

require_relative "core"

require_relative "function/color"
require_relative "function/file"
require_relative "function/locate"
require_relative "function/math"
require_relative "function/shell"
require_relative "function/string"
require_relative "function/ui"

require_relative "function/version"

module Sevgi
  # Support toolbox for Sevgi components and advanced extensions. The supported helper facade is {Sevgi::F}; it
  # provides degree-based trigonometry and precision, file discovery and output, argv-safe commands, naming helpers,
  # and small terminal status tools. It is not intended as a general-purpose utility library.
  #
  # {Function::Location}, {Function::Locate}, and {Function::Shell::Result} are public supporting values. The
  # thread-local precision accessors remain on {Function::Math.precision}. Other nested helper modules organize the
  # facade implementation and its method documentation; consumers should not include or extend them.
  #
  # @example Use the supported facade in library code
  #   Sevgi::F.with_precision(3) do
  #     Sevgi::F.cos(60)
  #     Sevgi::F.approx(1.0 / 3)
  #   end
  # @see https://sevgi.roktas.dev/functions/ Function toolbox guide
  module Function
  end

  # Supported helper facade for Sevgi extensions and advanced consumers.
  F = Function unless defined?(F)
end
