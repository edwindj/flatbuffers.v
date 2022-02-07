module flatbuffers

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

// assures for next token tokentype and consumes it, errors when it is not
fn (mut p Parser) expect(t TokenType) ?Token {
	p.sc.next()
	return p.assure(t)
}

// assures for current tokentype, errors when it is not
fn (mut p Parser) assure(t TokenType) ?Token {
	token := p.sc.current
	if token.tok != t {
		return error("Syntax error at line ${token.line}, expected '${t}' instead of '${token.lit}'")
	}
	return token
}

fn (mut p Parser) test(t TokenType) bool {
	return p.sc.current.tok == t
}


// schema = include* ( namespace_decl | type_decl | enum_decl | root_decl | file_extension_decl | file_identifier_decl | attribute_decl | rpc_decl | object )*
pub fn (mut p Parser) parse_schema() ?Schema {
	mut s := Schema{}
	mut token := p.sc.next()
	for token.tok != .eof {
		match token.tok {
			.include {
				incl := p.expect(.string_constant)?
				incl_file := incl.lit
				s.includes << incl_file
				eprintln("included file '${incl_file}' not parsed")
				//TODO parse the include file
			}
			.namespace { 
				ns := p.namespace_decl()?
				p.namespace = ns
				s.namespaces << ns
			}
			.table, .@struct { 
				t := p.type_decl()? 
				s.types << t
			}
			.@enum {
				e := p.enum_decl()?
				s.enums << e
			}
			.@union {
				u := p.union_decl()?
				s.unions << u
			}
			.attribute {
				att := p.expect(.ident)?
				s.attributes << att.lit
			}
// root_decl = root_type ident ;
			.root_type {
				rt := p.expect(.ident)?
				// TODO check if type is available?
				s.root = rt.lit
				p.expect(.semicolon)?
			}
			.file_extension {
				ext := p.expect(.string_constant)?
				s.file_extension = ext.lit
			}
			.file_identifier {
				id := p.expect(.string_constant)?
				s.file_identifier = id.lit
			}
			else {
				return error("Unexpected syntax at line: ${token.line}: ${token.lit}")
			}
		}
		// println("before: ${token}")
		token = p.sc.next()
		// println("after: ${token}")
	}
	p.schema = s
	return s
}

// include = include string_constant ;

// namespace_decl = namespace ident ( . ident )* ;
fn (mut p Parser) namespace_decl() ?string{
	mut token := p.expect(.ident)?
	
	mut namespace := token.lit

	token = p.sc.next()
	for token.tok == .dot {
		token = p.expect(.ident)?
		namespace += ".${token.lit}"
		token = p.sc.next()
	}
	p.assure(.semicolon)?
	// println("namespace = ${namespace}")
	return namespace
}


// attribute_decl = attribute ident | "ident" ;

// type_decl = ( table | struct ) ident metadata { field_decl+ }
fn (mut p Parser) type_decl() ?TypeDecl{
	td := p.sc.current.tok

	ident := p.expect(.ident)?

	// TODO store metadata
	mut token := p.sc.next()

	if token.tok == .lparen {
		m := p.metadata()?
		println("${m}")
		token = p.sc.next()
	}

	p.assure(.lbracket)? // {
	token = p.sc.next()
	mut fields := []FieldDecl{}
	for !(token.tok in [.rbracket, .eof]) {
		f := p.field_decl()?
		// println(f)
		fields << f
		token = p.sc.next()
		// break
	}
	p.assure(.rbracket)?  // }

	t := match td {
		.table {
			TypeDecl(TableDecl{name: ident.lit, fields: fields, ns: p.namespace})
		} else {
			TypeDecl(StructDecl{name: ident.lit, fields: fields, ns: p.namespace})
		}
	}
	return t
}

// enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
fn (mut p Parser) enum_decl() ?EnumDecl {
	
	name := p.expect(.ident)?
	p.expect(.colon)?

	mut token := p.sc.next()
	t := p.parse_type()?

	token = p.sc.next()
	if token.tok == .lparen {
		p.metadata()?
		token = p.sc.next()
		// ignore meta data
	}

	mut e := EnumDecl{name: name.lit, @type: t, ns: p.namespace}

	token = p.assure(.lbracket)?
	for token.tok != .eof {
		value := p.expect(.ident)?
		token = p.sc.next()
		int_value := match token.tok {
			.assign {
				ic := p.expect(.integer_constant)?
				token = p.sc.next()
				ic.lit
			} else {
				""
			}
		}
		e.values << value.lit
		e.int_values << int_value
		if token.tok != .comma {
			break
		}
	}
	p.assure(.rbracket)?
	return e
}

// enum_decl = ( enum ident : type | union ident ) metadata { commasep( enumval_decl ) }
fn (mut p Parser) union_decl() ?UnionDecl {
	name := p.expect(.ident)?

	mut token := p.sc.next()
	if token.tok == .lparen {
		p.metadata()?
		token = p.sc.next()
	}

	mut u := UnionDecl{name: name.lit, ns: p.namespace}

	token = p.assure(.lbracket)?
	for token.tok != .eof {
		value := p.expect(.ident)?
		u.values << value.lit
		token = p.sc.next()
		if token.tok != .comma {
			break
		}
	}
	p.assure(.rbracket)?
	return u
}


// field_decl = ident : type [ = scalar ] metadata ;
fn (mut p Parser) field_decl() ?FieldDecl{
	// println(p.sc.current)
	name := p.assure(.ident)?

	p.expect(.colon)?
	
	// type
	mut token := p.sc.next()
	ftype := p.parse_type()?

	mut f := FieldDecl{name: name.lit, @type: ftype}
	token = p.sc.next()
	if token.tok == .assign {
		// scalar parsing
		value := p.sc.next()
		if !(value.tok in [.boolean_constant, .float_constant, .string_constant, .integer_constant, .ident]) {
			return error("syntax error: expected constant value: ${value}")
		}
		f.default_value = value.lit
		token = p.sc.next()
	}
	if token.tok == .lparen {
		p.metadata()?
		p.sc.next()
	}
	p.assure(.semicolon)?

	return f
}

// type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident
fn (mut p Parser) parse_type()?string {
	mut token := p.sc.current
	s := match token.tok {
		.simple_type, .ident {
			token.lit
		}
		.lsqbracket {
			p.sc.next()
			a:= "[]" + p.parse_type()?
			p.expect(.rsqbracket)?
			a
		} else {
			""
		}
	}

	if s == "" {
		return error("expected a type definition, found ${token}")
	}
	return s
}

// rpc_decl = rpc_service ident { rpc_method+ }

// rpc_method = ident ( ident ) : ident metadata ;

// type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident

// enumval_decl = ident [ = integer_constant ]

// metadata = [ ( commasep( ident [ : single_value ] ) ) ]
fn (mut p Parser) metadata()? []string {
	p.assure(.lparen)?
	mut names := []string{}
	// comma separated list
	for {
		name := p.expect(.ident)?
		names << name.lit
		p.expect(.comma) or {
			break
		}
	}
	p.assure(.rparen)?
	return names
}

// scalar = boolean_constant | integer_constant | float_constant

// object = { commasep( ident : value ) }

// single_value = scalar | string_constant

// value = single_value | object | [ commasep( value ) ]

// commasep(x) = [ x ( , x )* ]

// file_extension_decl = file_extension string_constant ;

// file_identifier_decl = file_identifier string_constant ;

////// TOKENS
// string_constant = \".*?\\"

// ident = [a-zA-Z_][a-zA-Z0-9_]*

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
