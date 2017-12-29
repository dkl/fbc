#include once "crt/longdouble.bi"
extern "C"
type __fbbindgen_tempid_0
	as long dummy
end type
type NestedStruct1
	as long dummy
end type
enum NestedEnum1
	NestedEnum1_Dummy = 0ul
end enum
type Parent
	as __fbbindgen_tempid_0 a
	as NestedStruct1 b
	as NestedEnum1 c
end type
type NestedStruct2
	as long dummy
end type
type NestedStruct3
	as long dummy
end type
enum NestedEnum2
	NestedEnum2_Dummy = 0ul
end enum
type Foo
	as long dummy
end type
extern x1 as Foo
extern p1 as Foo ptr
type Bar
	as long dummy
end type
declare function f1 cdecl(byval as Bar) as Foo
type intptr_t as long
enum DummyEnum
	DummyEnumConst = 0ul
end enum
type StructInEnum
	as long dummy
end type
extern x2 as StructInEnum
end extern
