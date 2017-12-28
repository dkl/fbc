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
