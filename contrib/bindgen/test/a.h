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
