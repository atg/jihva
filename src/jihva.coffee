# --- Lexer ---
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

makeCounters = () ->
  return {
    '(': 0
    '[': 0
    '{': 0
  }

class Tokenizer
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
  
  tokenize: () ->
    @lexer.input = @source;
    while true
      x = @lexer.lex()
      if not x?
        break
    return @tokens
  
  tokenizeLines: (counters) ->
    # return a list of lines, taking care to balance brackets
    lines = [[]]
    toks = @tokenize()
    
    isDone = () ->
      return counters['('] == 0 and counters['['] == 0 and counters['{'] == 0
    
    adjust = (tok, left, right) ->
      if tok == left
        counters[left] += 1
      if tok == right
        counters[left] -= 1
    
    for tok in toks
      adjust(tok.val, '(', ')')
      adjust(tok.val, '[', ']')
      adjust(tok.val, '{', '}')
      if tok.kind == 'newline'
        if isDone()
          lines.push([])
          return
      lines[lines.length-1].push(tok)
    return [lines, isDone()]



# --- Parser ---
class Parser
  constructor: (toks) ->
    @toks = toks
  
  parse: () ->
    undefined


# --- Repl ---
readline = require 'readline'

class Repl
  constructor: (txt) ->
    undefined
  
  run: () ->
    @rl = readline.createInterface({
      'input': process.stdin,
      'output': process.stdout,
    })
    
    console.log("Jihva v1. Type 'quit' to quit")
    @counters = makeCounters()
    @step(true)
  
  eval: (txt) ->
    t = new Tokenizer(txt)
    # toks = t.tokenize()
    [lines, isDone] = t.tokenizeLines(@counters)
    lineOutputs = (JSON.stringify(line) for line in lines)
    return [lineOutputs.join('\n'), isDone]
    
  step: (isDone) ->
    prompt = " > "
    if not isDone
      prompt = '.. '
    
    @rl.question prompt, (answer) =>
      if answer == 'quit'
        @rl.close()
        return
      
      [output, isDone] = @eval(answer)
      console.log(output)
      @step(isDone) # run again

r = new Repl
r.run()
