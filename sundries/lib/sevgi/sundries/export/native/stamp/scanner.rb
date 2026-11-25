# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      module Stamp
        # Tokenizes a single PDF content stream and collects byte-offset stamp edits.
        # @api private
        class Scanner
          def initialize(data, stamp:, placeholder:, resources:)
            @data = data
            @stamp = stamp
            @placeholder = placeholder
            @fonts = resources&.[](:Font)
            @operands = []
            @state = {fill_white: false, font_name: nil, in_text: false, stack: [], valid: true}
            @edits = []
            @count = 0
          end

          def scan
            tokenizer = HexaPDF::Tokenizer.new(::StringIO.new(@data))

            loop do
              start = tokenizer.pos
              object = tokenizer.next_object(allow_keyword: true)
              break if object.equal?(HexaPDF::Tokenizer::NO_MORE_TOKENS)

              return [[], 0] unless consume?(object, start, tokenizer.pos)
            end

            return [[], 0] unless valid_end?

            raise @encoding_error if @encoding_error

            [@edits, @count]
          end

          private

          def consume?(object, start, finish)
            unless object.is_a?(HexaPDF::Tokenizer::Token)
              @operands << [object, start, finish]
              return true
            end

            # Inline image bytes are not PDF tokens; never interpret them as operators.
            operator = object.to_sym
            return false if operator == :BI || !HexaPDF::Content::Processor::OPERATOR_MESSAGE_NAME_MAP.key?(operator)

            process_operator(operator, finish)
            @operands.clear
            true
          end

          def valid_end? = @state[:valid] && @state[:stack].empty? && !@state[:in_text]

          def process_operator(operator, finish)
            case operator
            when :q, :Q
              handle_graphics_state(operator)
            when :rg, :g, :k, :cs, :sc, :scn
              handle_color_operator(operator)
            when :BT, :ET, :Tf
              handle_text_state(operator)
            when :Tj, :"'", :"\"", :TJ
              add_text_replacement(operator, finish)
            end
          end

          def handle_graphics_state(operator)
            if operator == :q
              @state[:stack] << @state.values_at(:fill_white, :font_name)
            elsif @state[:stack].any?
              @state[:fill_white], @state[:font_name] = @state[:stack].pop
            else
              @state[:valid] = false
            end
          end

          def handle_color_operator(operator)
            @state[:fill_white] = operator == :rg && @operands.size == 3 && @operands.all? { |val, *| val == 1 }
          end

          def handle_text_state(operator)
            case operator
            when :BT
              toggle_text(true)
            when :ET
              toggle_text(false)
            when :Tf
              name, size = @operands.map(&:first)
              @state[:font_name] = name if name.is_a?(::Symbol) && size.is_a?(::Numeric)
            end
          end

          def toggle_text(entering)
            @state[:valid] = false if @state[:in_text] == entering
            @state[:in_text] = entering
          end

          def add_text_replacement(operator, finish)
            return unless (replacement = text_replacement(operator))

            start, text_finish, text = replacement
            color_start = @operands.first.fetch(1)
            @edits << [start, text_finish, (start == color_start ? " 0.101961 0.101961 0.101961 rg#{text}" : text).b]
            @edits << Stamp.tint_edit(@data, color_start) unless start == color_start
            @edits << Stamp.tint_edit(@data, finish, white: true)
            @count += 1
          end

          def text_replacement(operator)
            return unless @state[:in_text] && @state[:fill_white] && @state[:font_name]

            value, start, finish = @operands.last || []
            replacement = encoded_replacement(operator, value)
            return unless replacement

            prefix = @data[start...finish].to_s[/\A\s*/]
            [start, finish, "#{prefix}#{replacement}"]
          end

          def encoded_replacement(operator, value)
            font = @fonts&.[](@state[:font_name])
            return unless font

            FontEncoding.replacement(font, value, array: operator == :TJ, stamp: @stamp, placeholder: @placeholder)
          rescue HexaPDF::Error => e
            @encoding_error ||= e
            nil
          end

        end

        # Maps PDF character codes to and from Unicode for the active font.
        # @api private
        module FontEncoding
          extend self

          def replacement(font, value, array:, stamp:, placeholder:)
            parts = text_parts(value, array:)
            return unless parts && decode(font, parts) == placeholder

            literal = Stamp.pdf_literal(encode(font, stamp))
            array ? "[#{literal}]" : literal
          end

          private

          def text_parts(value, array:)
            if array
              value.grep(::String) if value.is_a?(::Array)
            elsif value.is_a?(::String)
              [value]
            end
          end

          def decode(font, parts)
            codes = parts.flat_map { |part| font.decode(part) }
            characters = codes.filter_map { |code| unicode(font, code) }
            characters.join if characters.size == codes.size
          rescue HexaPDF::Error
            nil
          end

          def encode(font, text)
            template, max_code = code_format(font)
            codes = font.cache(:sevgi_stamp_codes) { build_map(font, max_code) }
            text
              .each_char
              .map do |char|
                codes.fetch(char) do
                  raise HexaPDF::Error, "Stamp character #{char.inspect} is unavailable in #{font[:BaseFont]}"
                end
              end
              .pack(template)
          end

          def code_format(font)
            return ["C*", 255] if font.is_a?(HexaPDF::Type::FontSimple)
            return ["n*", 65_535] if %i[Identity-H Identity-V].include?(font[:Encoding])

            raise HexaPDF::Error, "Unsupported stamp font encoding for #{font[:BaseFont]}"
          end

          def build_map(font, max_code)
            (0..max_code).each_with_object({}) do |code, map|
              char = unicode(font, code)
              map[char] ||= code if char
            end
          end

          def unicode(font, code)
            font.to_utf8(code)
          rescue HexaPDF::Error
            nil
          end
        end

        private_constant :FontEncoding

      end
    end
  end
end
