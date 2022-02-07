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

type TypeDecl = StructDecl | TableDecl

struct TableDecl {
	ns string
	name   string
	fields []FieldDecl
	metadata []string
}

struct FieldDecl {
mut:
	name     string
	@type    string
	default_value  string
	metadata Metadata
}

struct StructDecl {
	ns     string
	name   string
	fields []FieldDecl
}

struct EnumDecl {
mut:
    ns string
	name string
	@type string
	values []string
	int_values []string
}

struct UnionDecl {
mut:
    ns string
	name string
	values []string
}

struct Metadata {
}
