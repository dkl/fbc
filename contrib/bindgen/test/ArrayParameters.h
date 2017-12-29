void f1(int i[]);
extern void (*p1)(int i[]);
void f2(void (*p)(int i[]));

struct UDT {
    void (*p)(int i[]);
};

typedef struct C { int i; } C;
typedef C D[10];
struct UDT2 {
    void (*p)(const D x);
};
