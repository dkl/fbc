enum SingleConstEnum {
    SingleConst
};

enum SmallEnum {
    SmallEnum_default,
    SmallEnum_1 = 1,
    SmallEnum_123 = 123,
    SmallEnum_minus_1 = -1,
    SmallEnum_sizeof_int = sizeof (int),
};

static int _sizeof_SmallEnum = sizeof (enum SmallEnum);

enum BigInt64Enum {
    BigInt64Enum_default,
    BigInt64Enum_1 = 1,
    BigInt64Enum_123 = 123,
    BigInt64Enum_minus_1 = -1,
    BigInt64Enum_sizeof_int = sizeof (int),
    BigInt64Enum_max_uint32 = 0xFFFFFFFF,
    BigInt64Enum_max_uint32_ul = 0xFFFFFFFFul,
    BigInt64Enum_max_int64_ll = 0x7FFFFFFFFFFFFFFFll,
};

static int _sizeof_BigInt64Enum = sizeof (enum BigInt64Enum);

enum BigUInt64Enum {
    BigUInt64Enum_default,
    BigUInt64Enum_1 = 1,
    BigUInt64Enum_123 = 123,
    BigUInt64Enum_sizeof_int = sizeof (int),
    BigUInt64Enum_max_uint32 = 0xFFFFFFFF,
    BigUInt64Enum_max_uint32_ul = 0xFFFFFFFFul,
    BigUInt64Enum_max_int64_ll = 0x7FFFFFFFFFFFFFFFll,
    BigUInt64Enum_max_uint64_ull = 0xFFFFFFFFFFFFFFFFull,
};

static int _sizeof_BigUInt64Enum = sizeof (enum BigUInt64Enum);
