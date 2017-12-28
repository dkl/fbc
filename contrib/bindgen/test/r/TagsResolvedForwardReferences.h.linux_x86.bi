#include once "crt/longdouble.bi"
extern "C"
type ResolvedForwardStruct
	as long dummy
end type
type ResolvedForwardStruct_t as ResolvedForwardStruct
union ResolvedForwardUnion
	as long dummy
end union
type ResolvedForwardUnion_t as ResolvedForwardUnion
enum ResolvedForwardEnum
	dummy = 0ul
end enum
type ResolvedForwardEnum_t as ResolvedForwardEnum
end extern
