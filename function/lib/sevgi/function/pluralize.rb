# frozen_string_literal: true

module Sevgi
  module Function
    # Stolen and simplified from https://github.com/rails/rails/blob/main/activesupport/lib/active_support/inflector/inflections.rb
    module Pluralize
      # rubocop:disable Layout/SpaceInsideArrayPercentLiteral

      UNCOUNTABLES = Hash[
        *%w[
          sheep
          fish
          sheep
          series
          species
          money
          rice
          information
          equipment
        ].map { [ it, true ] }.flatten
      ].freeze

      IRREGULARS = Hash[
        *%w[
          child  children
          datum  data
          man    men
          move   moves
          person people
          sex    sexes
          woman  women
          zombie zombies
        ]
      ].freeze

      PLURALS = IRREGULARS.invert.freeze

      RULES = [
        [ /(quiz)$/i,                   '\1zes'   ],
        [ /^(oxen)$/i,                  '\1'      ],
        [ /^(ox)$/i,                    '\1en'    ],
        [ /^(m|l)ice$/i,                '\1ice'   ],
        [ /^(m|l)ouse$/i,               '\1ice'   ],
        [ /(matr|vert|ind)(?:ix|ex)$/i, '\1ices'  ],
        [ /(x|ch|ss|sh)$/i,             '\1es'    ],
        [ /([^aeiouy]|qu)y$/i,          '\1ies'   ],
        [ /(hive)$/i,                   '\1s'     ],
        [ /(?:([^f])fe|([lr])f)$/i,     '\1\2ves' ],
        [ /sis$/i,                      "ses"     ],
        [ /([ti])a$/i,                  '\1a'     ],
        [ /([ti])um$/i,                 '\1a'     ],
        [ /(buffal|tomat)o$/i,          '\1oes'   ],
        [ /(bu)s$/i,                    '\1ses'   ],
        [ /(alias|status)$/i,           '\1es'    ],
        [ /(octop|vir)i$/i,             '\1i'     ],
        [ /(octop|vir)us$/i,            '\1i'     ],
        [ /^(ax|test)is$/i,             '\1es'    ],
        [ /s$/i,                        "s"       ],
        [ /$/,                          "s"       ],
      ].freeze

      # Pluralize.('post')             # => "posts"
      # Pluralize.('octopus')          # => "octopi"
      # Pluralize.('sheep')            # => "sheep"
      # Pluralize.('words')            # => "words"
      # Pluralize.('CamelOctopus')     # => "CamelOctopi"
      def pluralize(word)
        result = word.to_s.dup

        return result if word.empty? || UNCOUNTABLES.key?(result) || PLURALS.key?(result)
        return IRREGULARS[result] if IRREGULARS.key?(result)

        RULES.each { |(rule, replacement)| break if result.sub!(rule, replacement) }
        result
      end
    end

    extend Pluralize
  end
end
