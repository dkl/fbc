#include once "crt/longdouble.bi"
extern "C"
type ResolvedForwardStruct
	as long dummy
end type
#assert sizeof(ResolvedForwardStruct) = 4
type ResolvedForwardStruct_t as ResolvedForwardStruct
union ResolvedForwardUnion
	as long dummy
end union
#assert sizeof(ResolvedForwardUnion) = 4
type ResolvedForwardUnion_t as ResolvedForwardUnion
enum ResolvedForwardEnum
	dummy = 0ul
end enum
#assert sizeof(ResolvedForwardEnum) = 4
type ResolvedForwardEnum_t as ResolvedForwardEnum
end extern
