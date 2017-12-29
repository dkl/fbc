#pragma GCC diagnostic ignored "-Wignored-attributes"

static int __storage_spec_on_procs;
static void f0(void);
extern void f1(void);

static int __nested_id;
void (f10)(void);
void ((f11))(void);
void (((f12)))(void);

static int __nested_declarator;
void (f20(void));
void ((f21(void)));
short *(f22(void));
short *(*f23(void));
short (*(*f24(void)));

static int __result_types;
void f30(void);
int f31(void);
int *f32(void);
struct UDT f33(void);
struct UDT **f34(void);

static int __result_procptr;
void (*f40(void))(void);
int (*f41(float, float))(double, double);
void (*(*f42(short int a))(short int b))(short int c);

static int __callconv;
__attribute__((stdcall)) void f50(int a, ...); // gcc: warning: stdcall calling convention ignored on variadic function [-Wignored-attributes]
__attribute__((cdecl)) void f51(void);
__attribute__((stdcall)) void f52(void);
