module flatbuffers

fn (sc Schema) to_v() string {
	mut ss := []string{}
	ss << "// Generated with flatbuffers.v"

	// for include in sc.includes {
	// 	ss << 'include "${include}";'
	// }
    
	mut namespaces := sc.namespaces.clone()
	namespaces.prepend("")
    for ns in namespaces {
		
		if ns != "" {
			ss << "module ${ns}"
		}

		for e in sc.enums.filter(it.ns == ns) {
			ss << e.to_v()
		}

		for t in sc.types.filter(it.ns == ns) {
			ss << t.to_v()
		}

		for u in sc.unions.filter(it.ns == ns) {
			ss << u.to_v()
		}
	}

	// These properties should be attached to the roottype with attributes
	//
	// if sc.file_extension != "" {
	// 	ss << 'file_extention = "${sc.file_extension}";'
	// }

	// if sc.file_identifier != "" {
	// 	ss << 'file_identifier = "${sc.file_identifier}";'
	// }


	// ss << "root_type = ${sc.root};"
	s := ss.join("\n\n")
	return s
}

fn (t TypeDecl) to_v() string {
	s := match t {
		TableDecl {
			t.to_v()
		}
		StructDecl {
			t.to_v()
		}
	}
	return s
}

fn (t TableDecl) to_v() string {
	fs := t.fields.map("    ${it.to_v()}").join('\n')
	s := "[flatbuffers:'table']
pub struct ${t.name} {
pub mut:
${fs}
}"
	return s
}

fn (f FieldDecl) to_v() string {
	dv := match f.default_value {
		"" {
			""
		} else {
			mut v := enum_value(f.default_value)
			// v0 := int(v.runes[0])
			// if v0 >= `a` && v0 <= `z` {
			// 	v = ".${v}"
			// }
			" = ${v}"	
		}
	}
	//TODO type convert
	vtype := v_type(f.@type)
	s := "${f.name} ${vtype}${dv}"
	return s
}

fn (t StructDecl) to_v() string {
	fs := t.fields.map("    ${it.to_v()}").join('\n')
	s := "[flatbuffers:'struct']
pub struct ${t.name} {
pub:
${fs}
}"
	return s
}

fn (e EnumDecl) to_v() string {
	// TODO fix issues with to lower
	mut values := []string{cap: e.values.len}
	for i, v in e.values {
		iv := e.int_values[i] 
		if  iv == "" {
			values << "   ${v.to_lower()}"
		} else {
			//TODO fix the enum values
			values << "   ${v.to_lower()} = ${iv}"
		}
	}
	s := "[flatbuffers:'type=${e.@type}']
enum ${e.name} {
${values.join('\n')}
}
"
	return s
}

fn (u UnionDecl) to_v() string {
	s := "[flatbuffers:'union']
pub type ${u.name} = ${u.values.join("| ")}"
	return s
}


fn v_type(s string) string{
	if s.starts_with('['){
		st := s[1..s.len-1]
		return "[]${v_type(st)}"
		// remove first and last character
		// and recurse
	}
// type = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident

	vtype := {
		'short' : 'i16'
		'ushort' : 'u16'
		'long'   : 'i64'
		'ulong'  : 'u64'
		'float' : 'f64'
		'int8'  : 'i8'
		'int16'  : 'i16'
		'int32'  : 'int'
		'int64'  : 'i64'
		'uint8'  : 'byte'
		'uint16'  : 'u16'
		'uint32'  : 'u32'
		'uint64'  : 'u64'
		'float32' : 'f32'
		'float64' : 'f64'
		'ubyte' : 'byte'
		'byte'  : 'i8'
	}

	return vtype[s] or {s}
}

fn enum_value(v string) string {
	val := v.to_lower()
	if val.len > 0 && !(val in ['false', 'true']) {
		b := 'az'.bytes()
		if val[0] >= b[0] && val[0] <= b[1] {
			return ".${val}"
		}
	}
	return val
}