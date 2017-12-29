#include once "crt/longdouble.bi"
extern "C"
type __fbbindgen_tempid_1
	as long a
end type
#assert sizeof(__fbbindgen_tempid_1) = 4
type __fbbindgen_tempid_0
	as long a
	union
		as __fbbindgen_tempid_1 b
		as long c
	end union
end type
#assert sizeof(__fbbindgen_tempid_0) = 8
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
#assert sizeof(Parent) = 12
type __fbbindgen_tempid_2
	as long a
end type
#assert sizeof(__fbbindgen_tempid_2) = 4
union __fbbindgen_tempid_3
	type
		as long b
	end type
	type
		as single c
	end type
	as __fbbindgen_tempid_0 d
end union
#assert sizeof(__fbbindgen_tempid_3) = 8
type __fbbindgen_tempid_4
	as long b
end type
#assert sizeof(__fbbindgen_tempid_4) = 4
union __fbbindgen_tempid_5
	as __fbbindgen_tempid_1 b
	as long c
end union
#assert sizeof(__fbbindgen_tempid_5) = 4
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
#assert sizeof(Nested) = 20
type __fbbindgen_tempid_6
	as long c
	union
		as long d
		as long e
	end union
	as long f
end type
#assert sizeof(__fbbindgen_tempid_6) = 12
union __fbbindgen_tempid_7
	as long d
	as long e
end union
#assert sizeof(__fbbindgen_tempid_7) = 4
type __fbbindgen_tempid_8
	as long j
	union
		as long k
		as long l
	end union
	as long m
end type
#assert sizeof(__fbbindgen_tempid_8) = 12
union __fbbindgen_tempid_9
	as long k
	as long l
end union
#assert sizeof(__fbbindgen_tempid_9) = 4
end extern
