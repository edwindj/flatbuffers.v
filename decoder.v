module flatbuffers

pub fn decode<T>(b []byte) ?T {
	error('not implemented')
}


	// mut result := T{}
	// // compile-time `for` loop
	// // T.fields gives an array of a field metadata type
	// $for field in T.fields {
	// 	$if field.typ is string {
	// 		// $(string_expr) produces an identifier
	// 		result.$(field.name) = get_string(data, field.name)
	// 	} $else $if field.typ is int {
	// 		result.$(field.name) = get_int(data, field.name)
	// 	}
	// }
	// return result