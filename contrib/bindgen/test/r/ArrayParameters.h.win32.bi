#include once "crt/longdouble.bi"
extern "C"
declare sub f1 cdecl(byval as long ptr)
extern p1 as sub cdecl(byval as long ptr)
declare sub f2 cdecl(byval as sub cdecl(byval as long ptr))
type UDT
	as sub cdecl(byval as long ptr) p
end type
#assert sizeof(UDT) = 4
type C
	as long i
end type
#assert sizeof(C) = 4
type C as C
type D as C
type UDT2
	as sub cdecl(byval as const C ptr) p
end type
#assert sizeof(UDT2) = 4
end extern
