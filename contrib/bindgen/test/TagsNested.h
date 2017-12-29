#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wvisibility"

struct Parent {
    struct { int dummy; } a; // field referencing nested anonymous struct/union/enum
    struct NestedStruct1 { int dummy; } b; // field referencing nested struct/union/enum
    enum NestedEnum1 { NestedEnum1_Dummy } c;

    // gcc/clang: warning: declaration does not declare anything [-Wmissing-declarations]
    struct NestedStruct2 { int dummy; };
    const struct NestedStruct3 { int dummy; };
    enum NestedEnum2 { NestedEnum2_Dummy };
};

// warning: declaration of 'struct Bar' will not be visible outside of this function [-Wvisibility]
extern struct Foo {
    int dummy;
} x1, *p1, f1(struct Bar { int dummy; });

#ifdef _WIN64
    typedef long long intptr_t;
#else
    typedef long intptr_t;
#endif

enum DummyEnum {
    DummyEnumConst = (intptr_t)(struct StructInEnum { int dummy; } *)0,
};

extern struct StructInEnum x2;
