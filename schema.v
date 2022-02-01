module flatbuffers

struct Schema {
mut:
	includes   []string
	root       string
	namespaces []string
	types      []Type
	enums      []Enum
}

type Type = Struct | Table

struct Table {
	fields []Field
}

struct Field<T> {
	name     string
	@type    string
	default  T
	metadata Metadata
}

struct Struct {
}

struct Enum {
}

struct Metadata {
}
