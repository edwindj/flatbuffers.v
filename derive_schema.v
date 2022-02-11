module flatbuffers

import v.ast

fn derive_schema<T>() ?Schema {
	mut s := Schema{}
	// compile-time `for` loop
	// T.fields gives an array of a field metadata type

	root := derive_table<T>(mut s)?
	//s.root = root.name

	return s
}

fn derive_table<T>(mut s Schema) ?T {
	name := T.name[1..]
	// println(T.attrs)
	println(name)
	mut t := T{}
	mut tb := TableDecl{name: name}
	$for field in T.fields {
		$if field.typ is string {
			tb.fields << FieldDecl{name:field.name, @type:"string"}
		} $else $if field.typ is int {
			tb.fields << FieldDecl{name:field.name, @type:"int"}
		} $else $if field.typ is f64 {
			tb.fields << FieldDecl{name:field.name, @type:"float64"}
		} $else $if field.typ is byte {
			tb.fields << FieldDecl{name:field.name, @type:"ubyte"}
		} $else {
			p := typeof(t.$(field.name)).name
			tb.fields << FieldDecl{name:field.name, @type: p[1..]}
		}
	}
	s.types << tb
	return t
}