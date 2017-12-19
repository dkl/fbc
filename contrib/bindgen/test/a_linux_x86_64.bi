extern var_char as byte
extern var_schar as byte
extern var_uchar as ubyte
extern var_short as short
extern var_sshort as short
extern var_ushort as ushort
extern var_int as long
extern var_sint as long
extern var_uint as ulong
extern var_long as ulongint
extern var_slong as ulongint
extern var_ulong as ulongint
extern var_longlong as ulongint
extern var_slonglong as ulongint
extern var_ulonglong as ulongint
extern var_float as single
extern var_double as double
extern var_ci as const long
extern var_pi as long ptr
extern var_pci as const long ptr
extern var_cpi as long const ptr
extern var_cpci_1 as const long const ptr
extern var_cpci_2 as const long const ptr
declare sub f1 cdecl()
declare function f2 cdecl(byval as long, byval as double) as long
declare sub f_variadic cdecl(byval as long, ...)
extern pf1 as sub cdecl()
extern pf2 as function cdecl(byval as long, byval as double) as long
