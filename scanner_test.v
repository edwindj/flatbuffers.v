module flatbuffers

fn test_scanner() {
	s := 'namespace test;

fiets  = "fiets.txt"
b = 1
c = 1.4
struct A {}
table B{a: string}
root_type test;
attribute i;
'

	mut sc := new_scanner(s)
	ns := sc.next()

	assert ns.tok == .namespace
	assert ns.lit == 'namespace'
	assert ns.line == 1

	mut token := sc.next()
	assert token.tok == .ident
	assert token.lit == "test"


	mut a := sc.next()
	// for a.tok != .eof {
	// 	print("'${a.lit}'<${a.tok}> ")
	// 	a = sc.next()
	// }
}

fn test_ws_before_eof(){
	s := "namespace test; 
"
	mut sc := new_scanner(s)
	mut a := sc.next()
	// for a.tok != .eof {
	// 	println("'${a.lit}'<${a.tok}> ")
	// 	a = sc.next()
	// }
	// println("'${a.lit}'<${a.tok}> ")
}

fn test_bool(){
	s := "false true bool"
	mut sc := new_scanner(s)
	mut b := sc.next()
	assert b.lit == "false"
	assert b.tok == .boolean_constant

	b = sc.next()
	assert b.tok == .boolean_constant
	assert b.lit == "true"

	b = sc.next()
	assert b.lit == "bool"
	assert b.tok == .simple_type
}


fn test_comment(){
	s := "true // this is a comment
	false"

	mut sc := new_scanner(s)
	mut tok := sc.next()
	println(tok)
	tok = sc.next()
	println(tok)
}
