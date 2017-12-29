#include once "crt/longdouble.bi"
extern "C"
dim shared __simple as long
declare sub f0 cdecl(byval as long)
declare sub f1 cdecl(byval as long, byval as long)
declare sub f2 cdecl(byval as long, byval as long, byval as long)
declare sub f3 cdecl(byval as long ptr, byval as long ptr ptr ptr)
dim shared __anonymous as long
declare sub f10 cdecl(byval as long)
declare sub f11 cdecl(byval as long ptr, byval as long, byval as long ptr ptr ptr, byval as long)
dim shared __arrays as long
declare sub f30 cdecl(byval as long ptr)
declare sub f31 cdecl(byval as long, byval as long ptr)
declare sub f32 cdecl(byval as long ptr, byval as long)
declare sub f33 cdecl(byval as long, byval as long ptr, byval as long)
declare sub f34 cdecl(byval as long ptr, byval as long ptr, byval as long ptr)
declare sub f35 cdecl(byval as long ptr)
dim shared __nested_id as long
declare sub f40 cdecl(byval as long)
declare sub f41 cdecl(byval as long, byval as long)
declare sub f42 cdecl(byval as long ptr, byval as long ptr ptr ptr, byval as long ptr)
dim shared __anonymous_nested_id as long
declare sub f50 cdecl(byval as long ptr ptr ptr, byval as long ptr)
dim shared __no_params as long
declare sub f60 cdecl(...)
declare sub f61 cdecl()
dim shared __procptr_params as long
declare sub f70 cdecl(byval as sub cdecl())
declare sub f71 cdecl(byval as sub cdecl())
declare sub f72 cdecl(byval as sub cdecl(byval as sub cdecl()))
declare sub f73 cdecl(byval as sub cdecl(byval as sub cdecl()))
dim shared __vararg as long
declare sub f80 cdecl(byval as long, ...)
dim shared __functions as long
declare sub f90 cdecl(byval as sub cdecl(...))
declare sub f91 cdecl(byval as sub cdecl(...))
declare sub f92 cdecl(byval as sub cdecl(...))
declare sub f93 cdecl(byval as sub cdecl())
declare sub f94 cdecl(byval as sub cdecl())
declare sub f95 cdecl(byval as sub cdecl())
declare sub f96 cdecl(byval as sub cdecl())
end extern
