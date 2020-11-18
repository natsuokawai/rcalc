require 'strscan'

module Rcalc
  Token = Struct.new(:kind, :str, :pos)
  TOKEN_NUM      = 'TOKEN_NUM'.freeze
  TOKEN_RESERVED = 'TOKEN_RESERVED'.freeze
  TOKEN_EOF      = 'TOKEN_EOF'.freeze

  class Lexer
    REGEXP_NUM      = /\d+/.freeze
    REGEXP_RESERVED = /[\+\-\*\/\(\)]/.freeze

    def initialize(input_str)
      raise ArgumentError, 'input_str should be String' unless input_str.is_a? String
      @scanner = StringScanner.new(input_str)
      @tokens  = []
    end

    attr_reader :tokens

    def tokenize
      until scanner.eos?
        # skip space character
        scanner.scan(/\s/)

        # tokenize number
        if scanner.check(REGEXP_NUM)
          pos = scanner.pos
          str = scanner.scan(REGEXP_NUM)
          tokens << Token.new(TOKEN_NUM, str, pos)
        end

        # tokenize +, -, *, /, (, )
        if scanner.check(REGEXP_RESERVED)
          pos = scanner.pos
          str = scanner.scan(REGEXP_RESERVED)
          tokens << Token.new(TOKEN_RESERVED, str, pos)
        end
      end

      tokens << Token.new(TOKEN_EOF, '', scanner.pos)
    end

    private

    attr_reader :scanner
  end
end
