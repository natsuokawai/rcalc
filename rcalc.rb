# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'
require 'strscan'

module Rcalc
  class Token < T::Struct
    extend T::Sig

    prop :kind, String
    prop :str, String
    prop :pos, Integer

    sig { returns(T::Boolean) }
    def eof?
      kind == TOKEN_EOF
    end
  end
  TOKEN_NUM      = 'TOKEN_NUM'
  TOKEN_RESERVED = 'TOKEN_RESERVED'
  TOKEN_EOF      = 'TOKEN_EOF'

  class Lexer
    extend T::Sig

    REGEXP_NUM      = /\d+/.freeze
    REGEXP_RESERVED = %r{[+\-*/()]}.freeze

    sig { params(input_str: String).void }
    def initialize(input_str)
      @scanner = StringScanner.new(input_str)
      @tokens  = T.let([], T::Array[Token])
      @cur_pos = T.let(0, Integer)
    end

    sig { returns(T::Array[Token]) }
    attr_accessor :tokens

    sig { returns(T::Array[Token]) }
    def tokenize
      until scanner.eos?
        # skip space character
        scanner.scan(/\s/)

        # tokenize number
        if scanner.check(REGEXP_NUM)
          pos = scanner.pos
          str = scanner.scan(REGEXP_NUM)
          tokens << Token.new(kind: TOKEN_NUM, str: str, pos: pos)
          next
        end

        # tokenize +, -, *, /, (, )
        if scanner.check(REGEXP_RESERVED)
          pos = scanner.pos
          str = scanner.scan(REGEXP_RESERVED)
          tokens << Token.new(kind: TOKEN_RESERVED, str: str, pos: pos)
          next
        end

        raise ArgumentError, 'Unexpected character'
      end

      tokens << Token.new(kind: TOKEN_EOF, str: '', pos: scanner.pos)
    end

    sig { returns(T.nilable Integer) }
    def next_token!
      @cur_pos += 1 if @cur_pos < tokens.size - 1
    end

    sig { returns(T.nilable Token) }
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

    sig { returns(Integer) }
    attr_reader :cur_pos
    attr_reader :scanner
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
      @l = Lexer.new(input_str)
      l.tokenize
    end

    attr_accessor :ast

    def parse
      @ast ||= expr

      raise ParseError, 'Extra token' unless l.cur_tok.eof?
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
          next
        when '/'
          l.next_token!
          node = Node.new(NODE_DIV, nil, node, primary)
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

      l.next_token! # skip "("
      node = expr

      raise ParseError, 'Expected ")"' unless l.cur_tok.str == ')'

      l.next_token! # skip ")"
      node
    end
  end

  class Evaluator
    def initialize(input_str)
      p = Parser.new(input_str)
      p.parse
      @ast = p.ast
    end

    def eval
      _eval(ast)
    end

    private

    attr_reader :ast

    def _eval(ast)
      case ast.kind
      when NODE_NUM
        ast.val
      when NODE_ADD
        _eval(ast.left) + _eval(ast.right)
      when NODE_SUB
        _eval(ast.left) - _eval(ast.right)
      when NODE_MUL
        _eval(ast.left) * _eval(ast.right)
      when NODE_DIV
        _eval(ast.left) / _eval(ast.right)
      end
    end
  end
end
