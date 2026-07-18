# frozen_string_literal: true

module Sevgi
  module Function
    # String helpers used by generated names and user-facing text.
    module String
      # Returns the final constant name segment from a module path.
      # @param path [Object] module, class, or string-like path
      # @return [String]
      def demodulize(path)
        path = path.to_s
        if (i = path.rindex("::"))
          path[(i + 2), path.length]
        else
          path
        end
      end
    end

    extend String

    # Lightweight English pluralization helper.
    module Pluralize
      # Words that should not be pluralized.
      # @api private
      UNCOUNTABLES = %w[
        equipment
        fish
        information
        money
        rice
        series
        sheep
        species
      ]
        .to_h { [it, true] }
        .freeze

      # Singular-to-plural forms that do not follow suffix rules.
      # @api private
      IRREGULARS = Hash[
        *%w[
          child
          children
          datum
          data
          man
          men
          move
          moves
          person
          people
          sex
          sexes
          woman
          women
          zombie
          zombies
        ]
      ]
        .freeze

      # Plural forms already accepted as plural.
      # @api private
      PLURALS = IRREGULARS.invert.freeze

      # Ordered suffix replacement rules.
      # @api private
      RULES = [
        [/(quiz)$/i, "\\1zes"],
        [/^(oxen)$/i, "\\1"],
        [/^(ox)$/i, "\\1en"],
        [/^(m|l)ice$/i, "\\1ice"],
        [/^(m|l)ouse$/i, "\\1ice"],
        [/(matr|vert|ind)(?:ix|ex)$/i, "\\1ices"],
        [/(x|ch|ss|sh)$/i, "\\1es"],
        [/([^aeiouy]|qu)y$/i, "\\1ies"],
        [/(hive)$/i, "\\1s"],
        [/(?:([^f])fe|([lr])f)$/i, "\\1\\2ves"],
        [/sis$/i, "ses"],
        [/([ti])a$/i, "\\1a"],
        [/([ti])um$/i, "\\1a"],
        [/(buffal|tomat)o$/i, "\\1oes"],
        [/(bu)s$/i, "\\1ses"],
        [/(alias|status)$/i, "\\1es"],
        [/(octop|vir)i$/i, "\\1i"],
        [/(octop|vir)us$/i, "\\1i"],
        [/^(ax|test)is$/i, "\\1es"],
        [/s$/i, "s"],
        [/$/, "s"]
      ]
        .each(&:freeze)
        .freeze

      private_constant :IRREGULARS, :PLURALS, :RULES, :UNCOUNTABLES

      # Pluralizes an English word using a small built-in rule set.
      # @param word [Object] word to pluralize
      # @return [String]
      # @example
      #   F.pluralize("post")         # => "posts"
      #   F.pluralize("octopus")      # => "octopi"
      #   F.pluralize("sheep")        # => "sheep"
      #   F.pluralize("CamelOctopus") # => "CamelOctopi"
      def pluralize(word)
        result = word.to_s.dup

        return result if result.empty? || UNCOUNTABLES.key?(result) || PLURALS.key?(result)
        return IRREGULARS[result] if IRREGULARS.key?(result)

        RULES.each { |(rule, replacement)| break if result.sub!(rule, replacement) }
        result
      end
    end

    extend Pluralize
  end
end
