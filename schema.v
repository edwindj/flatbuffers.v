module flatbuffers

struct Schema {
mut:
	includes   []string
	root       string
	namespaces []string
	types      []TypeDecl
	enums      []EnumDecl
	unions     []UnionDecl
	attributes []string
	file_extension string
	file_identifier string  // should be char 4
}

fn (sc Schema) str() string {
	mut ss := []string{}
	ss << "// Generated with flatbuffers.v"

	for include in sc.includes {
		ss << 'include "${include}";'
	}
    
	mut namespaces := sc.namespaces.clone()
	namespaces.prepend("")
    for ns in namespaces {
		
		if ns != "" {
			ss << "namespace ${ns};"
		}

		for e in sc.enums.filter(it.ns == ns) {
			ss << e.str()
		}

		for t in sc.types.filter(it.ns == ns) {
			ss << t.str()
		}

		for u in sc.unions.filter(it.ns == ns) {
			ss << u.str()
		}
	}

	if sc.file_extension != "" {
		ss << 'file_extention = "${sc.file_extension}";'
	}

	if sc.file_identifier != "" {
		ss << 'file_identifier = "${sc.file_identifier}";'
	}


	ss << "root_type = ${sc.root};"
	s := ss.join("\n\n")
	return s
}

type TypeDecl = StructDecl | TableDecl

fn (t TypeDecl) str() string {
	s := match t {
		TableDecl {
			t.str()
		}
		StructDecl {
			t.str()
		}
	}
	return s
}

struct TableDecl {
mut:
	ns string
	name   string
	fields []FieldDecl
	metadata []string
}

fn (t TableDecl) str() string {
	fs := t.fields.map("    ${it}").join('\n')
	s := "table ${t.name} {\n${fs}\n}"
	return s
}

struct FieldDecl {
mut:
	name     string
	@type    string
	default_value  string
	metadata Metadata
}

fn (f FieldDecl) str() string {
	dv := match f.default_value {
		"" {
			""
		} else {
			" = ${f.default_value}"	
		}
	}
	s := "${f.name}: ${f.@type}${dv};"
	return s
}

struct StructDecl {
	ns     string
	name   string
	fields []FieldDecl
}

fn (t StructDecl) str() string {
	fs := t.fields.map("    ${it}").join('\n')
	s := "struct ${t.name} {\n${fs}\n}"
	return s
}


struct EnumDecl {
mut:
    ns string
	name string
	@type string
	values []string
	int_values []string
}

fn (e EnumDecl) str() string {
	mut s := "enum ${e.name}: ${e.@type} {\n"
	mut values := []string{cap: e.values.len}
	for i, v in e.values {
		iv := e.int_values[i] 
		if  iv == "" {
			values << "   ${v}"
		} else {
			values << "   ${v} = ${iv}"
		}
	}
	s += values.join(",\n")
	s += "\n}"
	return s
}

struct UnionDecl {
mut:
    ns string
	name string
	values []string
}

fn (u UnionDecl) str() string {
	s := "union ${u.name} {${u.values.join(", ")}}"
	return s
}

struct RpcDecl {
mut:
	name string
	methods []RpcMethod
}

struct RpcMethod {
mut:
	name string
	param string
	ret string
	metadata Metadata
}

struct Metadata {
}

struct Object {
mut:
	props []KeyValue
}

struct KeyValue {
mut:
	key string
	value string
}
