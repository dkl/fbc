extern "C"
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
enum enum1
	enum1_const1 = 0ul
	enum1_const2 = 1ul
	enum1_const3 = 2ul
end enum
type enum1_t as enum1
extern var_enum1_1 as enum1
extern var_enum1_2 as enum1
enum SingleConstEnum
	SingleConst = 0ul
end enum
enum SmallEnum
	SmallEnum_default = 0l
	SmallEnum_1 = 1l
	SmallEnum_123 = 123l
	SmallEnum_minus_1 = -1l
	SmallEnum_sizeof_int = 4l
end enum
dim shared _sizeof_SmallEnum as long = 4ll
enum BigInt64Enum
	BigInt64Enum_default = 0ll
	BigInt64Enum_1 = 1ll
	BigInt64Enum_123 = 123ll
	BigInt64Enum_minus_1 = -1ll
	BigInt64Enum_sizeof_int = 4ll
	BigInt64Enum_max_uint32 = 4294967295ll
	BigInt64Enum_max_uint32_ul = 4294967295ll
	BigInt64Enum_max_int64_ll = 9223372036854775807ll
end enum
dim shared _sizeof_BigInt64Enum as long = 8ll
enum BigUInt64Enum
	BigUInt64Enum_default = 0ull
	BigUInt64Enum_1 = 1ull
	BigUInt64Enum_123 = 123ull
	BigUInt64Enum_sizeof_int = 4ull
	BigUInt64Enum_max_uint32 = 4294967295ull
	BigUInt64Enum_max_uint32_ul = 4294967295ull
	BigUInt64Enum_max_int64_ll = 9223372036854775807ull
	BigUInt64Enum_max_uint64_ull = 18446744073709551615ull
end enum
dim shared _sizeof_BigUInt64Enum as long = 8ll
type CircularReferenceB as __fbbindgen_forwardid_CircularReferenceB
type CircularReferenceA
	as CircularReferenceB ptr b
end type
type __fbbindgen_forwardid_CircularReferenceB
	as CircularReferenceA ptr a
end type
type ResolvedForwardStruct as __fbbindgen_forwardid_ResolvedForwardStruct
type ResolvedForwardStruct_t as ResolvedForwardStruct
type __fbbindgen_forwardid_ResolvedForwardStruct
	as long dummy
end type
type ResolvedForwardUnion as __fbbindgen_forwardid_ResolvedForwardUnion
type ResolvedForwardUnion_t as ResolvedForwardUnion
union __fbbindgen_forwardid_ResolvedForwardUnion
	as long dummy
end union
type ResolvedForwardEnum as __fbbindgen_forwardid_ResolvedForwardEnum
type ResolvedForwardEnum_t as ResolvedForwardEnum
enum __fbbindgen_forwardid_ResolvedForwardEnum
	dummy = 0ul
end enum
type UnresolvedForwardStruct as __fbbindgen_forwardid_UnresolvedForwardStruct
type UnresolvedForwardStruct_t as UnresolvedForwardStruct
type UnresolvedForwardUnion as __fbbindgen_forwardid_UnresolvedForwardUnion
type UnresolvedForwardUnion_t as UnresolvedForwardUnion
type UnresolvedForwardEnum as __fbbindgen_forwardid_UnresolvedForwardEnum
type UnresolvedForwardEnum_t as UnresolvedForwardEnum
end extern
