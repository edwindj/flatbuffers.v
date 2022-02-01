module flatbuffers

fn test_scanner() {
	s := 'namespace test;

fiets  = "fiets.txt"	
b = 1
c = 1.4
struct A {}
table B{a: string}
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
	for a.tok != .eof {
		println(a)
		a = sc.next()
	}
}