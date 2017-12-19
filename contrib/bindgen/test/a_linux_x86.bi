extern var_char as byte
extern var_schar as byte
extern var_uchar as ubyte
extern var_short as short
extern var_sshort as short
extern var_ushort as ushort
extern var_int as long
extern var_sint as long
extern var_uint as ulong
extern var_long as long
extern var_slong as long
extern var_ulong as ulong
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
type struct1
	as long field1
	as double field2
end type
type struct1_t as struct1
extern var_struct1_1 as struct1
extern var_struct1_2 as struct1
union union1
	as long field1
	as double field2
end union
type union1_t as union1
extern var_union1_1 as union1
extern var_union1_2 as union1
