#include once "crt/longdouble.bi"
extern "C"
dim shared __storage_spec_on_procs as long
declare sub f0 cdecl()
declare sub f1 cdecl()
dim shared __nested_id as long
declare sub f10 cdecl()
declare sub f11 cdecl()
declare sub f12 cdecl()
dim shared __nested_declarator as long
declare sub f20 cdecl()
declare sub f21 cdecl()
declare function f22 cdecl() as short ptr
declare function f23 cdecl() as short ptr ptr
declare function f24 cdecl() as short ptr ptr
dim shared __result_types as long
declare sub f30 cdecl()
declare function f31 cdecl() as long
declare function f32 cdecl() as long ptr
type UDT as __fbbindgen_forwardid_UDT
declare function f33 cdecl() as UDT
declare function f34 cdecl() as UDT ptr ptr
dim shared __result_procptr as long
declare function f40 cdecl() as sub cdecl()
declare function f41 cdecl(byval as single, byval as single) as function cdecl(byval as double, byval as double) as long
declare function f42 cdecl(byval as short) as function cdecl(byval as short) as sub cdecl(byval as short)
end extern
