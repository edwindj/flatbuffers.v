module flatbuffers

fn test_parse_schema(){
	schema := "namespace test;
" 
	parse(schema)

	parse("namespace test")
}