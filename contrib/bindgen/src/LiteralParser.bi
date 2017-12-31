#pragma once
#include once "AstNode.bi"

''
'' C number literal token parser
''
'' Supported cases:
''    123        (decimal)
''    .123       (decimal float)
''    123.123    (decimal float)
''    0xAABBCCDD (hexadecimal)
''    010        (octal)
''    010.0      (decimal float, not octal float)
''    0b10101    (binary)
'' There also is some simple float exponent and type suffix parsing.
''
'' We have to parse the number literal (but without type suffix) first before we
'' can decide whether it's an integer or float. This decides whether a leading
'' zero indicates octal or not.
''
type CNumberLiteralParser
private:
    tokentext as const string '' buffer
    p as const ubyte ptr '' null-terminated literal text
    as const ubyte ptr valuestart, valueend
    as boolean is_valid, is_float, have_nonoct_digit
    as boolean have_u, have_l, have_ll, have_f, have_d
    numbase as integer

    declare sub parseNonDecimalPrefix()
    declare sub parseBody()
    declare sub parseExponent()
    declare sub parseFloatTypeSuffixes()
    declare sub parseUSuffix()
    declare sub parseIntTypeSuffixes()
    declare sub parse()
    declare const function getType() as TypeKind
    declare const function getValueText() as string
    declare const function getValueAsFBToken() as string

public:
    declare constructor(byval tokentext as const zstring ptr)
    declare const function isValid() as boolean
    declare const function getValue() as ConstantValue
end type
