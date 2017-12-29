#include once "crt/longdouble.bi"
extern "C"
type A
	as long a : 1
	as long b : 1
end type
#assert sizeof(A) = 4
end extern
