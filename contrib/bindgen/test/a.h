extern char var_char;
extern signed char var_schar;
extern unsigned char var_uchar;

extern short var_short;
extern signed short var_sshort;
extern unsigned short var_ushort;

extern int var_int;
extern signed int var_sint;
extern unsigned int var_uint;

extern long var_long;
extern signed long var_slong;
extern unsigned long var_ulong;

extern long long var_longlong;
extern signed long long var_slonglong;
extern unsigned long long var_ulonglong;

extern float var_float;
extern double var_double;

extern const int var_ci;
extern int *var_pi;
extern int const *var_pci;
extern int *const var_cpi;
extern int const *const var_cpci_1;
extern const int *const var_cpci_2;

void f1(void);
int f2(int, double);
void f_variadic(int, ...);
extern void (*pf1)(void);
extern int (*pf2)(int, double);

struct struct1 {
    int field1;
    double field2;
};

typedef struct struct1 struct1_t;

extern struct struct1 var_struct1_1;
extern struct1_t var_struct1_2;

union union1 {
    int field1;
    double field2;
};

typedef union union1 union1_t;

extern union union1 var_union1_1;
extern union1_t var_union1_2;

enum enum1 {
    enum1_const1,
    enum1_const2,
    enum1_const3
};

typedef enum enum1 enum1_t;

extern enum enum1 var_enum1_1;
extern enum1_t var_enum1_2;

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

struct CircularReferenceA {
    struct CircularReferenceB *b;
};

struct CircularReferenceB {
    struct CircularReferenceA *a;
};

typedef struct ResolvedForwardStruct ResolvedForwardStruct_t;
struct ResolvedForwardStruct { int dummy; };

typedef union ResolvedForwardUnion ResolvedForwardUnion_t;
union ResolvedForwardUnion { int dummy; };

typedef enum ResolvedForwardEnum ResolvedForwardEnum_t;
enum ResolvedForwardEnum { dummy };

typedef struct UnresolvedForwardStruct UnresolvedForwardStruct_t;
typedef union UnresolvedForwardUnion UnresolvedForwardUnion_t;
typedef enum UnresolvedForwardEnum UnresolvedForwardEnum_t;
