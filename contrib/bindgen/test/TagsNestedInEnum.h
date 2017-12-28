#ifdef _WIN64
    typedef long long intptr_t;
#else
    typedef long intptr_t;
#endif

enum DummyEnum {
    DummyEnumConst = (intptr_t)(struct MyStruct { int dummyField; } *)0,
};

extern struct MyStruct x;
