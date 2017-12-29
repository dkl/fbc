#include once "crt/longdouble.bi"
extern "C"
type A field = 1
	as byte a
	as long b
end type
#assert sizeof(A) = 5
end extern
