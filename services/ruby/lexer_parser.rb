module Language
  class Token
    attr_reader :type, :value, :position

    def initialize(type, value, position)
      @type = type
      @value = value
      @position = position
    end

    def to_h
      { type: @type, value: @value, position: @position }
    end
  end

  class Lexer
    def initialize(input)
      @input = input
      @position = 0
      @tokens = []
    end

    def tokenize
      while @position < @input.length
        char = @input[@position]

        case char
        when /\s/
          @position += 1
        when /[a-zA-Z_]/
          read_identifier
        when /[0-9]/
          read_number
        when '"'
          read_string
        when /[+\-*\/]/
          @tokens << Token.new(:operator, char, @position)
          @position += 1
        when '('
          @tokens << Token.new(:lparen, char, @position)
          @position += 1
        when ')'
          @tokens << Token.new(:rparen, char, @position)
          @position += 1
        when '{'
          @tokens << Token.new(:lbrace, char, @position)
          @position += 1
        when '}'
          @tokens << Token.new(:rbrace, char, @position)
          @position += 1
        when ';'
          @tokens << Token.new(:semicolon, char, @position)
          @position += 1
        when '='
          if @input[@position + 1] == '='
            @tokens << Token.new(:equals, '==', @position)
            @position += 2
          else
            @tokens << Token.new(:assign, char, @position)
            @position += 1
          end
        else
          raise "Unexpected character: #{char}"
        end
      end

      @tokens << Token.new(:eof, nil, @position)
      @tokens
    end

    private

    def read_identifier
      start = @position

      while @position < @input.length && @input[@position] =~ /[a-zA-Z0-9_]/
        @position += 1
      end

      value = @input[start...@position]
      type = keyword?(value) ? :keyword : :identifier

      @tokens << Token.new(type, value, start)
    end

    def read_number
      start = @position

      while @position < @input.length && @input[@position] =~ /[0-9]/
        @position += 1
      end

      value = @input[start...@position].to_i
      @tokens << Token.new(:number, value, start)
    end

    def read_string
      @position += 1
      start = @position

      while @position < @input.length && @input[@position] != '"'
        @position += 1
      end

      value = @input[start...@position]
      @position += 1

      @tokens << Token.new(:string, value, start)
    end

    def keyword?(word)
      %w[if else while for function return var let const].include?(word)
    end
  end

  class ASTNode
    attr_reader :type, :value, :children

    def initialize(type, value = nil, children = [])
      @type = type
      @value = value
      @children = children
    end

    def to_h
      {
        type: @type,
        value: @value,
        children: @children.map(&:to_h)
      }
    end
  end

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @position = 0
    end

    def parse
      statements = []

      while !eof?
        statements << parse_statement
      end

      ASTNode.new(:program, nil, statements)
    end

    private

    def parse_statement
      case current_token.type
      when :keyword
        case current_token.value
        when 'var', 'let', 'const'
          parse_variable_declaration
        when 'if'
          parse_if_statement
        when 'while'
          parse_while_statement
        when 'function'
          parse_function_declaration
        when 'return'
          parse_return_statement
        end
      when :identifier
        parse_expression_statement
      else
        raise "Unexpected token: #{current_token.type}"
      end
    end

    def parse_variable_declaration
      keyword = consume(:keyword)
      name = consume(:identifier)
      consume(:assign)
      value = parse_expression
      consume(:semicolon)

      ASTNode.new(:variable_declaration, keyword.value, [
        ASTNode.new(:identifier, name.value),
        value
      ])
    end

    def parse_if_statement
      consume(:keyword)
      consume(:lparen)
      condition = parse_expression
      consume(:rparen)
      consume(:lbrace)

      body = []
      while current_token.type != :rbrace
        body << parse_statement
      end

      consume(:rbrace)

      ASTNode.new(:if_statement, nil, [condition, ASTNode.new(:block, nil, body)])
    end

    def parse_while_statement
      consume(:keyword)
      consume(:lparen)
      condition = parse_expression
      consume(:rparen)
      consume(:lbrace)

      body = []
      while current_token.type != :rbrace
        body << parse_statement
      end

      consume(:rbrace)

      ASTNode.new(:while_statement, nil, [condition, ASTNode.new(:block, nil, body)])
    end

    def parse_function_declaration
      consume(:keyword)
      name = consume(:identifier)
      consume(:lparen)
      consume(:rparen)
      consume(:lbrace)

      body = []
      while current_token.type != :rbrace
        body << parse_statement
      end

      consume(:rbrace)

      ASTNode.new(:function_declaration, name.value, body)
    end

    def parse_return_statement
      consume(:keyword)
      value = parse_expression
      consume(:semicolon)

      ASTNode.new(:return_statement, nil, [value])
    end

    def parse_expression_statement
      expr = parse_expression
      consume(:semicolon)
      expr
    end

    def parse_expression
      left = parse_term

      while current_token.type == :operator && ['+', '-'].include?(current_token.value)
        op = consume(:operator)
        right = parse_term
        left = ASTNode.new(:binary_expression, op.value, [left, right])
      end

      left
    end

    def parse_term
      left = parse_factor

      while current_token.type == :operator && ['*', '/'].include?(current_token.value)
        op = consume(:operator)
        right = parse_factor
        left = ASTNode.new(:binary_expression, op.value, [left, right])
      end

      left
    end

    def parse_factor
      case current_token.type
      when :number
        ASTNode.new(:number, consume(:number).value)
      when :string
        ASTNode.new(:string, consume(:string).value)
      when :identifier
        ASTNode.new(:identifier, consume(:identifier).value)
      when :lparen
        consume(:lparen)
        expr = parse_expression
        consume(:rparen)
        expr
      else
        raise "Unexpected token in factor: #{current_token.type}"
      end
    end

    def current_token
      @tokens[@position]
    end

    def consume(expected_type)
      token = current_token
      raise "Expected #{expected_type}, got #{token.type}" unless token.type == expected_type
      @position += 1
      token
    end

    def eof?
      current_token.type == :eof
    end
  end

  class Interpreter
    def initialize(ast)
      @ast = ast
      @variables = {}
      @functions = {}
    end

    def run
      @ast.children.each do |statement|
        execute(statement)
      end
    end

    private

    def execute(node)
      case node.type
      when :variable_declaration
        name = node.children[0].value
        value = evaluate(node.children[1])
        @variables[name] = value
      when :function_declaration
        @functions[node.value] = node
      when :return_statement
        evaluate(node.children[0])
      when :if_statement
        condition = evaluate(node.children[0])
        execute(node.children[1]) if condition
      when :while_statement
        while evaluate(node.children[0])
          execute(node.children[1])
        end
      when :block
        node.children.each { |stmt| execute(stmt) }
      else
        evaluate(node)
      end
    end

    def evaluate(node)
      case node.type
      when :number
        node.value
      when :string
        node.value
      when :identifier
        @variables[node.value]
      when :binary_expression
        left = evaluate(node.children[0])
        right = evaluate(node.children[1])

        case node.value
        when '+' then left + right
        when '-' then left - right
        when '*' then left * right
        when '/' then left / right
        end
      end
    end
  end
end
