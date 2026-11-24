# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      module Stamp
        # Tokenizes a single PDF content stream and collects byte-offset stamp edits.
        # @api private
        class Scanner
          def initialize(data, stamp:, placeholder:)
            @data = data
            @stamp = stamp
            @placeholder = placeholder
            @serializer = HexaPDF::Serializer.new
            @operands = []
            @state = {fill_white: false, font_size: nil, in_text: false, stack: [], valid: true}
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

            valid_end? ? [@edits, @count] : [[], 0]
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
              @state[:stack] << @state.values_at(:fill_white, :font_size)
            elsif @state[:stack].any?
              @state[:fill_white], @state[:font_size] = @state[:stack].pop
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
              @state[:font_size] = @operands.last&.first if @operands.size >= 2
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
            return unless @state[:in_text] && @state[:fill_white] && @state[:font_size]

            value, start, finish = @operands.last || []
            replacement = encoded_replacement(operator, value)
            return unless replacement

            prefix = @data[start...finish].to_s[/\A\s*/]
            [start, finish, "#{prefix}#{replacement}"]
          end

          def encoded_replacement(operator, value)
            if operator == :TJ
              return unless value.is_a?(::Array) && value.grep(::String).join == @placeholder

              @serializer.serialize_array([@stamp])
            elsif value.is_a?(::String) && value == @placeholder
              Stamp.pdf_literal(@stamp)
            end
          end
        end
      end
    end
  end
end
