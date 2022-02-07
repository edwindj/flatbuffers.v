module flatbuffers

import strings.textscanner
import regex
import os

struct Token {
	line int
	lit  string
	tok  TokenType = .unknown
}

fn (t Token) str() string {
	return "line $t.line, $t.tok: '$t.lit'"
}

enum TokenType {
	unknown
	include
	namespace
	@struct
	table
	simple_type
	@union
	attribute
	@enum
	ident
	file_identifier
	file_extension
	lparen // {
	rparen // }
	lbracket // {
	rbracket // }
	lsqbracket // []
	rsqbracket // ]
	semicolon // ;
	colon // :
	assign // =
	comma // ,
	dot // .
	root_type
	string_constant
	integer_constant
	float_constant
	boolean_constant
	eof
}

struct Scanner {
mut:
	line int = 1
	ts   textscanner.TextScanner
	current Token
	file string
}

// create a scanner from a path to a text file
fn scan_fbs(path string) ?&Scanner {
	s := os.read_file(path) ?
	mut sc := new_scanner(s)
	sc.file = path
	return sc
}

// create a scanner from a string
fn new_scanner(s string) &Scanner {
	sc := &Scanner{
		ts: textscanner.new(s)
	}
	return sc
}

// consume whitespace
fn (mut sc Scanner) ws() {
	if sc.ts.peek() == -1 {
		return
	}

	mut ts := &sc.ts
	for {
		mut c := ts.peek()
		match rune(c) {
			` `, `\t`, `\r` {
				ts.skip()
				c = ts.peek()
			}
			`\n` {
				ts.skip()
				sc.line += 1
				c = ts.peek()
			}
			else {
				break
			}
		}
	}
}

const (
	// whitespace characters
	ws_chars     = [` `, `\n`, `\t`, `\r`]

	// TODO create mapping to v types
	simple_types = ['bool', 'byte', 'ubyte', 'short', 'ushort', 'int', 'uint', 'float', 'long',
		'ulong', 'double', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64',
		'float32', 'float64', 'string']

	// single char tokens
	token_char   = {
		`{`: TokenType.lbracket
		`}`: TokenType.rbracket
		`(`: TokenType.lparen
		`)`: TokenType.rparen
		`[`: TokenType.lsqbracket
		`]`: TokenType.rsqbracket
		`:`: TokenType.colon
		`;`: TokenType.semicolon
		`"`: TokenType.string_constant
		`,`: TokenType.comma
		`=`: TokenType.assign
		`.`: TokenType.dot
	}

	// keywords
	token_keyword = {
		'include':   TokenType.include
		'namespace': TokenType.namespace
		'union':     TokenType.@union
		'table':     TokenType.table
		'struct':    TokenType.@struct
		'attribute': TokenType.attribute
		'root_type': TokenType.root_type
		'enum'     : TokenType.@enum
		'file_extension' : TokenType.file_extension
		'file_identifier': TokenType.file_identifier
	}

	// complex regex tokens
	token_re = {
		'^[A-z][A-z0-9_]*$':                                                 TokenType.ident
		'^(true)|(false)$':                                                  TokenType.boolean_constant
		'^[-+]?[0-9]+$':                                                     TokenType.integer_constant
		'^[-+]?(([.][0-9]+)|([0-9]+[.][0-9]*)|([0-9]+))([eE][-+]?[0-9]+)?$': TokenType.float_constant
	}
)

fn (mut sc Scanner) next() Token {
	// consume white space
	sc.ws()
	// TODO comment

	mut c := sc.ts.peek()
	if c == -1 {
		// println('eof?')
		return Token{
			line: sc.line
			tok: .eof
			lit: ''
		}
	}

	mut r := []rune{cap: 20}
	mut tok := token_char[c] or { TokenType.unknown }

	if tok != .unknown {
		r << sc.ts.next()
		if tok == .string_constant {
			for {
				c = sc.ts.next()
				r << c
				if c == `"` {
					break
				}
			}
		}
	} else {
		// match single character tokens
		for {
			c = sc.ts.peek()
			if c in ws_chars || c in token_char {
				break
			}
			if sc.ts.next() == -1 {
				break
			}
			r << c
		}
	}

	s := r.string()
	// match keywords
	tok = token_keyword[s] or {tok}

	if s in simple_types {
		tok = .simple_type
	}

    // match complex tokens
	if tok == .unknown {
		for qry, tok2 in token_re {
			mut re := regex.regex_opt(qry) or { panic(err.msg) }
			start, _ := re.match_string(s)
			if start >= 0 {
				tok = tok2
				break
			}
		}
	}

	// Should there be an error when tok is still unknown?
	// For debugging this is less useful...
	sc.current =  Token{
		line: sc.line
		tok: tok
		lit: s
	}	
	return sc.current
}

fn (mut sc Scanner) peek() Token {
	// store position in textbuffer
	rem := sc.ts.remaining()
	token := sc.next()

	// and skip back
	sc.ts.back_n(rem - sc.ts.remaining())

	return token
}
