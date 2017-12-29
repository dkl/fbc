struct UDT {
    signed int _1;
    unsigned long long int _2;
    unsigned _3;
    double _4,_5,_6;
    struct UDT *_7;

    int **_10, *_11, _12;
    int _13, **_14, **_15;
    int *_16, _17, _18, **_19, **_20, _21;

    int ****_30;
    int *_31, ****_32, _33;

    int _40_bitfield_1 : 1;
    int _41_bitfield_3 : 3;
    int _42_bitfield_27 : 27;
    int _43_bitfield_21 : 1 + 5 * 4;
    int _44_bitfield_1 : 1, _45_bitfield_1 : 1;
    int _46_bitfield_31 : (sizeof(int) * 8) - 1;

    int _50_array_20[20];
    int _51_array_2_3[2][3];
    void (*_52_array_40_of_procptr[40])(void);
    void (*_53_array_2_3_of_procptr[2][3])(void);

    void (*_60)(void);
    void (*_61)();
    int **(*_62)(int *, int ***), (*_63)(int, void (*)(void), int ***(*)(int ***));
    int *(**_64_ptr_to_procptr)(void);
};
