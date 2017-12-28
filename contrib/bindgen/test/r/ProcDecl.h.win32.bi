#include once "crt/longdouble.bi"
extern "C"
declare sub f1 cdecl()
declare function f2 cdecl(byval as long, byval as double) as long
declare sub f_variadic cdecl(byval as long, ...)
end extern
