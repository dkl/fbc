#include once "crt/longdouble.bi"
extern "C"
type A as __fbbindgen_forwardid_A
type B
	as A ptr a
end type
#assert sizeof(B) = 4
type __fbbindgen_forwardid_A
	as B ptr b
end type
#assert sizeof(__fbbindgen_forwardid_A) = 4
end extern
