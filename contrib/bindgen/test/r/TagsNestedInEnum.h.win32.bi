#include once "crt/longdouble.bi"
extern "C"
type intptr_t as long
enum DummyEnum
	DummyEnumConst = 0ul
end enum
type MyStruct
	as long dummyField
end type
extern x as MyStruct
end extern