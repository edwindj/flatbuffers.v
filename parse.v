module flatbuffers

import strings.textscanner

type Scanner = textscanner.TextScanner

struct Sscanner {
mut: 
   sc textscanner.TextScanner
   line int
pub mut:
   schema Schema
}

pub fn parse(s string){
	mut sc := textscanner.new(s)
	parse_schema(mut sc) or {panic(error)}
}

fn consume_ws(mut sc Scanner){
	mut c := sc.peek()
	for {
		match rune(c) {
			` `, `\t` { 
				sc.next()
				c = sc.peek()
			}
			`\n` {
				sc.next()
				// update line
				c = sc.peek()
			}
			else {break}
		}
	}
}

[inline]
fn expect(mut sc Scanner, s string){
	runes := s.runes()
	for c in runes {
		if sc.next() != c {
			println("expected '$s'")
		}
	}
}

fn comment(mut sc Scanner) string {
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

fn consume_word(mut sc Scanner) string {
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
fn peek_word(mut sc Scanner) string {
	word := consume_word(mut sc)
	sc.back_n(word.len)
	return word
}

// schema = include* ( namespace_decl | type_decl | enum_decl | root_decl | file_extension_decl | file_identifier_decl | attribute_decl | rpc_decl | object )*
pub fn parse_schema(mut sc Scanner) ?{
	for sc.remaining() > 0 {
		word := peek_word(mut sc)
		match word {
			"namespace" { parse_namespace_decl(mut sc) }
			else {
				sc.goto_end()
				error("Unexpected keyword: '$word'")
			}
		}
	}
}


// include = include string_constant ;

// namespace_decl = namespace ident ( . ident )* ;
fn parse_namespace_decl(mut sc Scanner) string {
	expect(mut sc, "namespace")

	mut namespace := parse_ident(mut sc)
	if sc.peek() == `.` {
		namespace += "." + parse_ident(mut sc)
	}
	consume_ws(mut sc)
	expect(mut sc, ";")
	println("namespace $namespace")
	return namespace
}

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

// ident = [a-zA-Z_][a-zA-Z0-9_]*
fn parse_ident(mut sc Scanner) string {
	consume_ws(mut sc)
	mut ident := []rune{}
	mut c := sc.peek()
	if (c >= `A` && c <= `z`) || (c == `_`) {
			ident << rune(sc.next())
			c = sc.peek()
			for (c >= `A` && c <= `z`) || (c == `_`) || (c >= `0` && c <= `9`) {
				ident << rune(sc.next())
				c = sc.peek()
			}
	} else {
		return ""
	}

	return ident.string()
}

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


