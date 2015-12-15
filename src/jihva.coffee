Lexer = require 'lex'

STRING_RE = /"(\\[\s\S]|[^"\\])+"/   # "hello\nworld"
NUMBER_RE = /\d+(\.\d+)/             # 3.14
IDENT_RE = /[\w_][\w\d_]*/           # _foo10
NEWLINE_RE = /\n/
COMMENT_RE = /\/\/[^\n]*/            # // a comment

SYMBOL_RE = /[^\w\s\d"'_]+/          # ::
WHITESPACE_RE = /\s+/

makeToken = (kind, val) ->
  return {
    "kind": kind,
    "val": val
  }

class Parser
  constructor: (txt) ->
    @source = txt
    @tokens = []
    @lexer = new Lexer
    
    # Primary rules
    @lexer.addRule STRING_RE, (tok) =>
      @tokens.push(makeToken('string', tok))
    
    @lexer.addRule NUMBER_RE, (tok) =>
      @tokens.push(makeToken('number', tok))
    
    @lexer.addRule IDENT_RE, (tok) =>
      @tokens.push(makeToken('ident', tok))
    
    @lexer.addRule NEWLINE_RE, (tok) =>
      @tokens.push(makeToken('newline', tok))
    
    @lexer.addRule COMMENT_RE, (tok) =>
      undefined
      
    # Secondary rules
    @lexer.addRule SYMBOL_RE, (tok) =>
      @tokens.push(makeToken('symbol', tok))
    
    @lexer.addRule WHITESPACE_RE, (tok) =>
      undefined
  
  parse: () ->
    @lexer.input = @source;
    while true
      x = @lexer.lex()
      if not x?
        break
    return @tokens

p = new Parser('print ("hello world")')
toks = p.parse()
console.log(toks)
