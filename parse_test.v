module flatbuffers

fn test_parse_schema() {
	schema := 'namespace test;
'
	parse(schema) or { panic(error) }

	parse('namespace test') or { panic(error) }
}
