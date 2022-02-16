module flatbuffers

import v.ast

fn derive_schema<T>() ?Schema {
	mut s := Schema{}
	// compile-time `for` loop
	// T.fields gives an array of a field metadata type
	t := T{}
	s.root = derive_table<T>(t, mut s)
	//s.root = root.name

	return s
}

fn derive_table<T>(t T, mut s Schema) string{
	tn := "$T.name"[1..]
	mut tb := TableDecl{name: T.name[1..]}
	$for field in T.fields {
		println(field)
		val := t.$(field.name)
		$if field.typ is string {
			tb.fields << FieldDecl{name:field.name, @type:"string"}
		} $else $if field.typ is int {
			tb.fields << FieldDecl{name:field.name, @type:"int"}
		} $else $if field.typ is f64 {
			tb.fields << FieldDecl{name:field.name, @type:"float64"}
		} $else $if field.typ is byte {
			tb.fields << FieldDecl{name:field.name, @type:"ubyte"}
		} $else {
			p := typeof(t.$(field.name)).name[1..]
			tbls := s.types.map(it.name)
			if !(p in tbls) {
				derive_table(val, mut s)
			}

			tb.fields << FieldDecl{name:field.name, @type: p}
		}
	}
	s.types << tb
	return tn
}