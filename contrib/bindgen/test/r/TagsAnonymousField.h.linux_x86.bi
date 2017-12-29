#include once "crt/longdouble.bi"
extern "C"
type __fbbindgen_tempid_1
	as long a
end type
type __fbbindgen_tempid_0
	as long a
	union
		as __fbbindgen_tempid_1 b
		as long c
	end union
end type
type Parent
	type
		as long a
	end type
	union
		type
			as long b
		end type
		type
			as single c
		end type
		as __fbbindgen_tempid_0 d
	end union
end type
type __fbbindgen_tempid_2
	as long a
end type
union __fbbindgen_tempid_3
	type
		as long b
	end type
	type
		as single c
	end type
	as __fbbindgen_tempid_0 d
end union
type __fbbindgen_tempid_4
	as long b
end type
union __fbbindgen_tempid_5
	as __fbbindgen_tempid_1 b
	as long c
end union
union Nested
	as long a
	as long b
	type
		as long c
		union
			as long d
			as long e
		end union
		as long f
	end type
	as long g
	type
		as long h
	end type
	type
		as long i
		union
			type
				as long j
				union
					as long k
					as long l
				end union
				as long m
			end type
			as long n
		end union
		as long o
	end type
	as long p
end union
type __fbbindgen_tempid_6
	as long c
	union
		as long d
		as long e
	end union
	as long f
end type
union __fbbindgen_tempid_7
	as long d
	as long e
end union
type __fbbindgen_tempid_8
	as long j
	union
		as long k
		as long l
	end union
	as long m
end type
union __fbbindgen_tempid_9
	as long k
	as long l
end union
end extern
