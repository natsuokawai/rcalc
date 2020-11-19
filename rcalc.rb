require 'strscan'

module Rcalc
  Token = Struct.new(:kind, :str, :pos) do
    def eof?
      kind == TOKEN_EOF
    end
  end
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
      @cur_pos = 0
    end

    attr_accessor :tokens, :cur_tok

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

    def next_token!
      @cur_pos += 1 if @cur_pos < tokens.size - 1
    end

    def cur_tok
      tokens[cur_pos]
    end

    def print_tokens
      puts "kind\t\tstr\tpos"
      tokens.each do |tok|
        puts "#{tok.kind}\t#{tok.str}\t#{tok.pos}"
      end
    end

    private

    attr_reader :scanner, :cur_pos
  end
  Node = Struct.new(:kind, :val, :left, :right)
  NODE_NUM = 'NODE_NUM'
  NODE_ADD = 'NODE_ADD'
  NODE_SUB = 'NODE_SUB'
  NODE_MUL = 'NODE_MUL'
  NODE_DIV = 'NODE_DIV'

  class ParseError < StandardError; end

  class Parser
    def initialize(input_str)
      raise ArgumentError, 'input_str should be String' unless input_str.is_a? String
      @l = Lexer.new(input_str)
      l.tokenize
      @ast = parse
    end

    attr_accessor :ast

    def parse
      expr
    end

    def print_ast
      pp ast.to_h
    end

    private

    attr_accessor :l

    # expr = add
    def expr
      add
    end

    # add = mul ("+" mul | "-" mul)*
    def add
      node = mul
      
      loop do
        case l.cur_tok.str
        when '+'
          l.next_token!
          node = Node.new(NODE_ADD, nil, node, mul)
          next
        when '-'
          l.next_token!
          node = Node.new(NODE_SUB, nil, node, mul)
          next
        else
          return node
        end
      end
    end

    # mul = primary ("*" primary | "/" primary)*
    def mul
      node = primary

      loop do
        case l.cur_tok.str
        when '*'
          l.next_token!
          node = Node.new(NODE_MUL, nil, node, primary)
          #l.next_token!
          next
        when '/'
          l.next_token!
          node = Node.new(NODE_DIV, nil, node, primary)
          #l.next_token!
          next
        else
          return node
        end
      end
    end

    # primary = num | "(" expr ")"
    def primary
      tok = l.cur_tok
      
      if tok.kind == TOKEN_NUM
        node = Node.new(NODE_NUM, tok.str.to_i)
        l.next_token!
        return node
      end

      raise ParseError, 'Expected "("' unless tok.str == '('
      l.next_token!

      node = expr

      raise ParseError, 'Expected ")"' unless l.cur_tok.str == ')'
      l.next_token!

      node
    end
  end
end
