_ = require 'lodash'

# --- Lexer ---
Lexer = require 'lex'

STRING_RE = /"(\\[\s\S]|[^"\\])+"/   # "hello\nworld"
NUMBER_RE = /-?\d+(\.\d+)?/          # -3.14
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
    @lexer.input = @source
    while true
      ok = @lexer.lex()
      if not ok?
        break
    return @tokens



# Splits a list of tokens into lines, taking care to balance brackets

class LineSplitter
  constructor: (toks, counters) ->
    @toks = toks
    if counters?
      @counters = counters
    else
      @counters = makeCounters()
  
  splitLines: () ->
    lines = [[]]
    
    isDone = () =>
      return @counters['('] == 0 and @counters['['] == 0 and @counters['{'] == 0
    
    adjust = (tok, left, right) =>
      if tok == left
        @counters[left] += 1
      if tok == right
        @counters[left] -= 1
    
    for tok in @toks
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
'''
class Parser
  constructor: (toks) ->
    @toks = toks
    @i = 0
  
  # Parsing utilities
  peek: () ->
    @toks[@i]
  forwards: () ->
    @i += 1
  pop: () ->
    tok = @peek()
    @forwards()
    return tok
  
  
  # Low-level token manipulation
  expect: (kind, val) ->
    tok = @peek()
    kindMatches = tok.kind == kind
    valMatches = !val? or tok.val == val
    if not kindMatches
      throw "Expected a #{kind}, instead got a #{tok.kind}"
    if not valMatches
      throw "Expected '#{val}', instead got '#{tok.val}'"
    return @pop()
  
  expectIdent: () ->
    return @expect("ident", null)
  expectSymbol: (val) ->
    return @expect("symbol", val)
  
  
  # High-level parsing
  parseRoot: () ->
    undefined
  
  parseFnDecl: () ->
    'fn add a b { ... }'
    name = @expectIdent()
    
    args = []
    while true
      try
        ident = @expectIdent()
        args.push(ident)
      catch
        break
    
    block = @parseBlock()
  
  parseBlock: () ->
    @expectSymbol('{')
    lines = new LineSplitter(toks)
    @expectSymbol('}')
'''

ARITY = {}
INTRINSICS = {}


makeMathFn2 = (key, fn) ->
  ARITY[key] = 2
  INTRINSICS[key] = (vals) ->
    a = Number(vals[0].val)
    b = Number(vals[1].val)
    return { "kind": "number", "val": String(fn(a, b)) }

makeMathFn2('+', (a, b) -> (a + b))
makeMathFn2('-', (a, b) -> (a - b))
makeMathFn2('*', (a, b) -> (a * b))
makeMathFn2('/', (a, b) -> (a / b))
makeMathFn2('%', (a, b) -> (a - b*Math.floor(a/b)))

class SimpleMachine
  constructor: () ->
    @variables = {}
    @stack = []
    
    for own k, v of INTRINSICS
      @setVariable([], k, {
        'kind': 'intrinsic',
        'val': k
      })
  
  getVariable: (path, key) ->
    path = path.slice()
    path.push(key)
    @variables[path.join(';')]
  
  setVariable: (path, key, val) ->
    path = path.slice()
    path.push(key)
    @variables[path.join(';')] = val
  
  eval: (lines) ->
    path = []
    for line in lines
      for tok in line
        switch tok.kind
          when 'number'
            @stack.push(tok)
          when 'string'
            @stack.push(tok)
          when 'ident', 'symbol'
            v = @getVariable(path, tok.val)
            if v.kind == 'intrinsic'
              fn = INTRINSICS[v.val]
              arity = ARITY[v.val]
              args = []
              for n in [0...arity]
                val = @stack.pop()
                args.push(val)
              args.reverse()
              result = fn(args)
              @stack.push(result)
    return

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
    toks = t.tokenize()
    
    ls = new LineSplitter(toks, @counters)
    [lines, isDone] = ls.splitLines()
    
    machine = new SimpleMachine()
    machine.eval(lines)
    
    outputs = (JSON.stringify(item.val) for item in machine.stack)
    
    # lineOutputs = (JSON.stringify(line) for line in lines)
    # return [lineOutputs.join('\n'), isDone]
    return [outputs.join(' '), isDone]
    
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
