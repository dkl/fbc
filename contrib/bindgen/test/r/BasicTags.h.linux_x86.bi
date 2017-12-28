extern "C"
type struct1
	as long field1
	as double field2
end type
type struct1_t as struct1
extern var_struct1_1 as struct1
extern var_struct1_2 as struct1
union union1
	as long field1
	as double field2
end union
type union1_t as union1
extern var_union1_1 as union1
extern var_union1_2 as union1
enum enum1
	enum1_const1 = 0ul
	enum1_const2 = 1ul
	enum1_const3 = 2ul
end enum
type enum1_t as enum1
extern var_enum1_1 as enum1
extern var_enum1_2 as enum1
end extern
