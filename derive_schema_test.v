module flatbuffers

struct Fruit {
	name string // naam
	tree Tree
}

struct Tree {
	species string
	age int
}

fn test_derive(){
	s := derive_schema<Fruit>() or {
		eprintln(err)
		Schema{}
	}
	println(s)
}