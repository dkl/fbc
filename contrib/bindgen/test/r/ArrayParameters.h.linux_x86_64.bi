#include once "crt/longdouble.bi"
extern "C"
declare sub f1 cdecl(byval as long ptr)
extern p1 as sub cdecl(byval as long ptr)
declare sub f2 cdecl(byval as sub cdecl(byval as long ptr))
type UDT
	as sub cdecl(byval as long ptr) p
end type
type C
	as long i
end type
type C as C
type D as C
type UDT2
	as sub cdecl(byval as const C ptr) p
end type
end extern
