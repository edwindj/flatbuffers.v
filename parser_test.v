module flatbuffers

fn test_parse_schema() {
	mut schema := 'namespace test;'
	mut p := new_parser(schema)
	p.parse_schema() or {println(err)}
	assert p.namespace == "test"
	// println(p.namespace)

	schema = 'namespace test.bla;'
	p = new_parser(schema)
	p.parse_schema() or {println(err)}
	assert p.namespace == "test.bla"
	// println(p.namespace)
}


fn test_table(){
	schema := 'table my_table {
		name : string;
		id: string;
		age: int = 18;
	}'

	mut p := new_parser(schema)
	s := p.parse_schema() or {
		println(err)
		Schema{}
	}

	assert s.types.len == 1
	t := s.types[0]
	assert t.fields.len == 3

	name := t.fields[0]
	assert name.name == 'name'
	assert name.@type == 'string'

	age := t.fields[2]
	assert age.name == "age"
	assert age.@type == "int"
	assert age.default_value == "18"

	// println(s)
}


fn test_enum(){
	schema := 'enum my_enum : byte {a, b, c}'
	mut p := new_parser(schema)
	s := p.parse_schema() or {panic(err.msg)}
	assert s.enums.len == 1
	e := s.enums[0]
	assert e.name == "my_enum"
	assert e.@type == "byte"
	assert e.values == ['a','b','c']
	assert e.int_values == ['','','']
}

fn test_error(){
	mut schema := 'namespace test'
	mut p := new_parser(schema)
	p.parse_schema() or {
		assert err.msg == "Syntax error at line 1, expected a 'semicolon' instead of 'test'"
	}
}

fn test_union()?{
mut schema := "
union Equipment { Weapon }

table Weapon {
  name:string;
  damage:short;
}"
	mut p := new_parser(schema)
	// println(p)
	s := p.parse_schema() or {
		println(err)
		Schema{}
	}
	// println(s)
}

fn test_eof(){
	mut schema := "namespace test;
	"

	mut p := new_parser(schema)
	s := p.parse_schema() or {
		println(err)
		Schema{}
	}
	assert "test" in s.namespaces
	// println(s)
}

fn test_field_decl(){
	fbs := "table Test {
   b:bool;
   w:[Weapons];
}"
    mut p := new_parser(fbs)
	s := p.parse_schema() or {
		println(err)
		Schema{}
	}

	println(s)
}


fn test_monster_fbs()?{
mut schema := "
namespace MyGame.Sample;

enum Color:byte { Red = 0, Green, Blue = 2 }

union Equipment { Weapon }

struct Vec3 {
  x:float;
  y:float;
  z:float;
}

table Monster {
  pos:Vec3;
  mana:short = 150;
  hp:short = 100;
  name:string;
  friendly:bool = false (deprecated);
  inventory:[ubyte];
  color:Color = Blue;
  weapons:[Weapon];
  equipped:Equipment;
  path:[Vec3];
}

table Weapon {
  name:string;
  damage:short;
}

root_type Monster;"
	mut p := new_parser(schema)
	s := p.parse_schema() or {
		println(err)
		Schema{}
	}
	println(s.to_v())
}