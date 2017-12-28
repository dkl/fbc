extern "C"
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
end extern
