module flatbuffers

import strings.textscanner

type TScanner = textscanner.TextScanner

struct Parser {
mut:
   sc &Scanner
   namespace string
   schema Schema
}

fn new_parser(s string) &Parser {
	mut sc := new_scanner(s)
	p := &Parser{sc: sc}
	return p	
}

struct FBSScanner {
mut:
	ts   textscanner.TextScanner
	line int = 1
pub mut:
	schema Schema
}

pub fn parse(s string) ?Schema {
	mut ts := textscanner.new(s)
	mut sc := FBSScanner{
		ts: ts
		line: 1
	}

	sc.parse_schema() ?
	return sc.schema
}

fn (mut sc FBSScanner) consume_ws() {
	mut ts := &sc.ts
	mut c := ts.peek()
	for {
		match rune(c) {
			` `, `\t` {
				ts.next()
				c = ts.peek()
			}
			`\n` {
				ts.next()
				// update line
				c = ts.peek()
			}
			else {
				break
			}
		}
	}
}

fn consume_ws(mut ts TScanner) {
	mut c := ts.peek()
	for {
		match rune(c) {
			` `, `\t` {
				ts.next()
				c = ts.peek()
			}
			`\n` {
				ts.next()
				// update line
				c = ts.peek()
			}
			else {
				break
			}
		}
	}
}

[inline]
fn expect(mut sc TScanner, s string) {
	runes := s.runes()
	for c in runes {
		if sc.next() != c {
			println("expected '$s'")
		}
	}
}

fn comment(mut sc TScanner) string {
	mut comment := []rune{}
	if sc.peek() == `/` && sc.peek_n(1) == `/` {
		sc.skip_n(2)
		mut c := sc.next()
		for c != -1 && c != `\n` {
			comment << c
			c = sc.next()
		}
	}
	return comment.string()
}

fn consume_word(mut sc TScanner) string {
	consume_ws(mut sc)
	mut word := []rune{}
	mut c := sc.peek()
	for c >= `A` && c <= `z` {
		sc.next()
		word << c
		c = sc.peek()
	}
	return word.string()
}

// peek might consume whitespace
fn peek_word(mut sc TScanner) string {
	word := consume_word(mut sc)
	sc.back_n(word.len)
	return word
}

// schema = include* ( namespace_decl | type_decl | enum_decl | root_decl | file_extension_decl | file_identifier_decl | attribute_decl | rpc_decl | object )*
pub fn (mut sc FBSScanner) parse_schema() ? {
	mut ts := &sc.ts
	for ts.remaining() > 0 {
		word := peek_word(mut ts)
		match word {
			'namespace' {
				sc.parse_namespace_decl()
			}
			'roottype' {
				error('not implemented')
			}
			'enum' {
				error('not implemented')
			}
			'include' {
				sc.include()
			}
			else {
				error("Unexpected keyword: '$word' at line $sc.line")
			}
		}
		sc.consume_ws()
	}
}

// pub fn parse_schema(mut sc TScanner) ?{
// 	for sc.remaining() > 0 {
// 		word := peek_word(mut sc)
// 		match word {
// 			"namespace" { parse_namespace_decl(mut sc) }
// 			else {
// 				sc.goto_end()
// 				error("Unexpected keyword: '$word'")
// 			}
// 		}
// 	}
// }

// include = include string_constant ;
fn (mut sc FBSScanner) include() string {
	mut ts := &sc.ts
	expect(mut ts, 'include')
	consume_ws(mut ts)
	return string_constant(mut ts)
}

// namespace_decl = namespace ident ( . ident )* ;

fn (mut sc FBSScanner) parse_namespace_decl() string {
	mut ts := &sc.ts
	expect(mut ts, 'namespace')

	mut namespace := sc.ident()
	if ts.peek() == `.` {
		namespace += '.' + sc.ident()
	}
	consume_ws(mut ts)
	expect(mut ts, ';')
	println('namespace $namespace')
	return namespace
}

// fn parse_namespace_decl(mut sc TScanner) string {
// 	expect(mut sc, "namespace")

// 	mut namespace := parse_ident(mut sc)
// 	if sc.peek() == `.` {
// 		namespace += "." + parse_ident(mut sc)
// 	}
// 	consume_ws(mut sc)
// 	expect(mut sc, ";")
// 	println("namespace $namespace")
// 	return namespace
// }

// attribute_decl = attribute ident | "ident" ;

// type_decl = ( table | struct ) ident metadata { field_decl+ }

// enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }

// root_decl = root_type ident ;

// field_decl = ident : type [ = scalar ] metadata ;

// rpc_decl = rpc_service ident { rpc_method+ }

// rpc_method = ident ( ident ) : ident metadata ;

// type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident

// enumval_decl = ident [ = integer_constant ]

// metadata = [ ( commasep( ident [ : single_value ] ) ) ]

// scalar = boolean_constant | integer_constant | float_constant

// object = { commasep( ident : value ) }

// single_value = scalar | string_constant

// value = single_value | object | [ commasep( value ) ]

// commasep(x) = [ x ( , x )* ]

// file_extension_decl = file_extension string_constant ;

// file_identifier_decl = file_identifier string_constant ;

// string_constant = \".*?\\"
fn string_constant(mut ts TScanner) string {
	mut sconstant := []rune{}

	mut c := ts.next()
	if c == `"` {
		c = ts.next()
		for c != `"` {
			sconstant << c
			c = ts.next()
		}
	}
	return sconstant.string()
}

// ident = [a-zA-Z_][a-zA-Z0-9_]*
fn (mut sc FBSScanner) ident() string {
	mut ts := &sc.ts
	sc.consume_ws()
	mut ident := []rune{}
	mut c := ts.peek()
	if (c >= `A` && c <= `z`) || (c == `_`) {
		ident << rune(ts.next())
		c = ts.peek()
		for (c >= `A` && c <= `z`) || (c == `_`) || (c >= `0` && c <= `9`) {
			ident << rune(ts.next())
			c = ts.peek()
		}
	} else {
		return ''
	}

	return ident.string()
}

// fn parse_ident(mut sc TScanner) string {
// 	consume_ws(mut sc)
// 	mut ident := []rune{}
// 	mut c := sc.peek()
// 	if (c >= `A` && c <= `z`) || (c == `_`) {
// 			ident << rune(sc.next())
// 			c = sc.peek()
// 			for (c >= `A` && c <= `z`) || (c == `_`) || (c >= `0` && c <= `9`) {
// 				ident << rune(sc.next())
// 				c = sc.peek()
// 			}
// 	} else {
// 		return ""
// 	}

// 	return ident.string()
// }

// [:digit:] = [0-9]

// [:xdigit:] = [0-9a-fA-F]

// dec_integer_constant = [-+]?[:digit:]+

// hex_integer_constant = [-+]?0[xX][:xdigit:]+

// integer_constant = dec_integer_constant | hex_integer_constant

// dec_float_constant = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?

// hex_float_constant = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)

// special_float_constant = [-+]?(nan|inf|infinity)

// float_constant = dec_float_constant | hex_float_constant | special_float_constant

// boolean_constant = true | false
