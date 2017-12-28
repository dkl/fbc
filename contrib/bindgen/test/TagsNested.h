struct Parent {
    struct {
        int a;
    } a; // field referencing nested anonymous struct/union/enum
    struct Nested {
        int b;
    } b; // field referencing nested struct/union/enum
};
