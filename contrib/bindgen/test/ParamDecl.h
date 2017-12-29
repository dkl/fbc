static int __simple;
void f0(int a);
void f1(int a, int b);
void f2(int a, int b, int c);
void f3(int *a, int ***b);

static int __anonymous;
void f10(int);
void f11(int *, int, int ***, int);

#if 0
static int __initializers;
void f20(int i = 123);
void f21(int a, int b = 123);
void f23(int a = 123, int b);
void f24(int a, int b = 123, int c);
void f25(int a = 1, int b = 2, int c = 3);
void f26(void (*p)(int) = 0);
void f27(void (*p)(int i = 123) = 0);
#endif

static int __arrays;
void f30(int i[5]);
void f31(int a, int b[20]);
void f32(int a[20], int b);
void f33(int a, int b[20], int c);
void f34(int a[1], int b[2], int c[3]);
void f35(int a[]);

static int __nested_id;
void f40(int (a));
void f41(int ((a)), int (b));
void f42(int *(a), int *(*((*b))), int (*c));

static int __anonymous_nested_id;
void f50(int *(*((*))), int (*));

static int __no_params;
void f60();
void f61(void);

static int __procptr_params;
void f70(void (*a)(void));
void f71(void (* )(void));
void f72(void (*a)(void (*b)(void)));
void f73(void (* )(void (* )(void)));

static int __vararg;
void f80(int a, ...);

static int __functions;
void f90(void ());
void f91(void (()));
void f92(void ((())));
void f93(void (void));
void f94(void ((void)));
void f95(void (((void))));
void f96(void f(void));
