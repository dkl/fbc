#include once "crt/longdouble.bi"
extern "C"
type __fbbindgen_tempid_0
	as long dummy
end type
#assert sizeof(__fbbindgen_tempid_0) = 4
type NestedStruct1
	as long dummy
end type
#assert sizeof(NestedStruct1) = 4
enum NestedEnum1
	NestedEnum1_Dummy = 0ul
end enum
#assert sizeof(NestedEnum1) = 4
type Parent
	as __fbbindgen_tempid_0 a
	as NestedStruct1 b
	as NestedEnum1 c
end type
#assert sizeof(Parent) = 12
type NestedStruct2
	as long dummy
end type
#assert sizeof(NestedStruct2) = 4
type NestedStruct3
	as long dummy
end type
#assert sizeof(NestedStruct3) = 4
enum NestedEnum2
	NestedEnum2_Dummy = 0ul
end enum
#assert sizeof(NestedEnum2) = 4
type Foo
	as long dummy
end type
#assert sizeof(Foo) = 4
extern x1 as Foo
extern p1 as Foo ptr
type Bar
	as long dummy
end type
#assert sizeof(Bar) = 4
declare function f1 cdecl(byval as Bar) as Foo
type intptr_t as long
enum DummyEnum
	DummyEnumConst = 0ul
end enum
#assert sizeof(DummyEnum) = 4
type StructInEnum
	as long dummy
end type
#assert sizeof(StructInEnum) = 4
extern x2 as StructInEnum
end extern
