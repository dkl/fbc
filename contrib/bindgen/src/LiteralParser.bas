#include once "LiteralParser.bi"
#include once "crt/mem.bi"

private function isBinDigit(byval c as ubyte) as boolean
    return (c = asc("0")) or (c = asc("1"))
end function

private function isDecDigit(byval c as ubyte) as boolean
    return (c >= asc("0")) and (c <= asc("9"))
end function

private function isHexDigit(byval c as ubyte) as boolean
    select case as const c
    case asc("0") to asc("9"), asc("A") to asc("F"), asc("a") to asc("f")
        return true
    end select
    return false
end function

sub CNumberLiteralParser.parseNonDecimalPrefix()
    '' 0, 0x, 0X, 0b, 0B
    if p[0] = asc("0") then
        select case p[1]
        case asc("b"), asc("B")
            p += 2
            numbase = 2
        case asc("x"), asc("X")
            p += 2
            numbase = 16
        case asc("0") to asc("9")
            p += 1
            numbase = 8
        end select
    end if
end sub

'' Body (integer part + fractional part, if any)
sub CNumberLiteralParser.parseBody()
    select case numbase
    case 2
        while isBinDigit(*p)
            p += 1
        wend

    case 16
        while isHexDigit(*p)
            p += 1
        wend

    case else
        do
            select case as const *p
            case asc("0") to asc("7")
                '' These digits are allowed in both dec/oct literals
            case asc("8"), asc("9")
                '' These digits are only allowed in dec literals, not
                '' oct, but we don't know which it is yet.
                have_nonoct_digit = true
            case asc(".")
                '' Only one dot allowed
                if is_float then
                    exit do
                end if
                is_float = true
            case else
                exit do
            end select
            p += 1
        loop
    end select
end sub

sub CNumberLiteralParser.parseExponent()
    '' Exponent? (can be used even without fractional part, e.g. '1e1')
    select case *p
    case asc("e"), asc("E")
        is_float = true
        p += 1

        '' ['+' | '-']
        select case *p
        case asc("+"), asc("-")
            p += 1
        end select

        '' ['0'-'9']*
        while isDecDigit(*p)
            p += 1
        wend
    end select
end sub

sub CNumberLiteralParser.parseFloatTypeSuffixes()
    select case *p
    case asc("f"), asc("F")
        p += 1
        have_f = true
    case asc("d"), asc("D")
        p += 1
        have_d = true
    end select
    is_float or= have_f or have_d
end sub

sub CNumberLiteralParser.parseUSuffix()
    select case *p
    case asc("u"), asc("U")
        p += 1
        have_u = true
    end select
end sub

'' Integer type suffixes:
''  l, ll, ul, ull, lu, llu
'' MSVC-specific ones:
''  [u]i{8|16|32|64}
'' All letters can also be upper-case.
sub CNumberLiteralParser.parseIntTypeSuffixes()
    parseUSuffix()

    select case *p
    case asc("l"), asc("L")
        p += 1
        select case *p
        case asc("l"), asc("L")
            p += 1
            have_ll = true
        case else
            have_l = true
        end select

        if not have_u then
            parseUSuffix()
        end if

    case asc("i"), asc("I")
        select case p[1]
        case asc("8")
            p += 2
        case asc("1")
            if p[2] = asc("6") then
                p += 3
            end if
        case asc("3")
            if p[2] = asc("2") then
                p += 3
            end if
        case asc("6")
            if p[2] = asc("4") then
                p += 3
                have_ll = true
            end if
        end select
    end select
end sub

sub CNumberLiteralParser.parse()
    parseNonDecimalPrefix()

    valuestart = p
    parseBody()
    parseExponent()
    valueend = p

    if numbase = 8 then
        '' Floats with leading zeroes are decimal, not octal.
        if is_float then
            numbase = 10
        elseif have_nonoct_digit then
            '' Error: Invalid digit in octal number literal
            return
        end if
    end if

    parseFloatTypeSuffixes()
    if not is_float then
        parseIntTypeSuffixes()
    end if

    if *p <> 0 then
        '' Error: Didn't reach end of number literal
        return
    end if

    is_valid = true
end sub

const function CNumberLiteralParser.getType() as TypeKind
    '' Assuming certain type sizes, instead of using clang_Type_getSizeOf() or similar,
    '' because we don't have a CXType here. It's probably ok for the FB binding though.
    if is_float then
        '' Floats can have f/d suffixes, or default to double.
        return iif(have_f, Type_Float32, Type_Float64)
    end if
    return iif(have_u, Type_UInt64, Type_Int64)
end function

const function CNumberLiteralParser.getValueText() as string
    var length = valueend - valuestart
    var text = space(length)
    memcpy(strptr(text), valuestart, length)
    return text
end function

const function CNumberLiteralParser.getValueAsFBToken() as string
    dim s as string
    select case numbase
    case 2
        s = "&b"
    case 8
        s = "&o"
    case 16
        s = "&h"
    end select
    s += getValueText()
    return s
end function

constructor CNumberLiteralParser(byval tokentext as const zstring ptr)
    cast(string, this.tokentext) = *tokentext
    p = strptr(this.tokentext)
    numbase = 10
    parse()
end constructor

const function CNumberLiteralParser.isValid() as boolean
    return is_valid
end function

const function CNumberLiteralParser.getValue() as ConstantValue
    dim c as ConstantValue
    c.dtype = DataType(getType())
    c.fbtoken = getValueAsFBToken()
    return c
end function
