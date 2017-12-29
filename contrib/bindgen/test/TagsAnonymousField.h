struct Parent {
    struct {
        int a;
    };
    union {
        struct {
            int b;
        };
        struct {
            float c;
        };
        struct {
            int a;
            union {
                struct {
                    int a;
                } b;
                int c;
            };
        } d;
    };
};

union Nested {
    int a;
    int b;
    struct {
        int c;
        union {
            int d;
            int e;
        };
        int f;
    };
    int g;
    struct { int h; };
    struct {
        int i;
        union {
            struct {
                int j;
                union {
                    int k;
                    int l;
                };
                int m;
            };
            int n;
        };
        int o;
    };
    int p;
};
