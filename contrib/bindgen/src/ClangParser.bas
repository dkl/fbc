#include once "ClangParser.bi"
#include once "Util.bi"

constructor TUParser(byval tu as ClangTU ptr)
    this.tu = tu
    ast = new AstNode(AstKind_Group)
end constructor

destructor TUParser()
    delete ast
end destructor

const sub TUParser.checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    assertOrAbort(condition, _
        "sizeof " + wrapstr(clang_getTypeSpelling(ty)) + _
        " is " & clang_Type_getSizeOf(ty) & " bytes, " + _
        "expected " + expected)
end sub

const sub TUParser.checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    checkBasicTypeSize(clang_Type_getSizeOf(ty) = expected, ty, str(expected))
end sub

const function TUParser.parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    select case clang_Type_getSizeOf(ty)
    case 1
        return iif(is_signed, Type_Int8, Type_Uint8)
    case 2
        return iif(is_signed, Type_Int16, Type_Uint16)
    case 4
        return iif(is_signed, Type_Int32, Type_Uint32)
    case 8
        return iif(is_signed, Type_Int64, Type_Uint64)
    case else
        checkBasicTypeSize(false, ty, "1, 2, 4 or 8")
    end select
end function

const function TUParser.parseSimplyType(byval ty as CXType) as TypeKind
    select case as const ty.kind
    case CXType_Void
        return Type_Void

    case CXType_Bool
        '' TODO: Use FB boolean? It's supposed to be ABI-compatible to GCC's _Bool afterall...
        checkBasicTypeSize(ty, 1)
        return Type_Uint8

    case CXType_Char_S, CXType_SChar, _
         CXType_Short, CXType_Int, CXType_Long, CXType_LongLong
        return parseIntType(ty, true)

    case CXType_Char_U, CXType_UChar, _
         CXType_UShort, CXType_UInt, CXType_ULong, CXType_ULongLong
        return parseIntType(ty, false)

    case CXType_Float
        checkBasicTypeSize(ty, 4)
        return Type_Float32

    case CXType_Double
        checkBasicTypeSize(ty, 8)
        return Type_Float64

    end select

    return Type_None
end function

const function TUParser.parseType(byval ty as CXType) as FullType
    dim t as FullType

    select case as const ty.kind
    case CXType_Pointer
        t = parseType(clang_getPointeeType(ty))
        t.dtype = t.dtype.addrOf()

    case else
        dim t as FullType
        t.dtype = t.dtype.withBase(parseSimplyType(ty))
        if t.dtype.basetype() = Type_None then
            abortProgram("unhandled clang type " + tu->dumpType(ty))
        end if
    end select

    if clang_isConstQualifiedType(ty) then
        t.dtype.setConst()
    end if

    return t
end function

function TUParser.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    select case clang_getCursorKind(cursor)
    case CXCursor_VarDecl
        var n = new AstNode(AstKind_Var)
        n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
        n->sym.t = parseType(clang_getCursorType(cursor))
        ast->append(n)

    case CXCursor_MacroDefinition
        '' TODO

    case else
        abortProgram("unhandled cursor kind: " + wrapstr(clang_getCursorKindSpelling(clang_getCursorKind(cursor))))
    end select

    return CXChildVisit_Continue
end function

sub TUParser.parse()
    visitChildrenOf(clang_getTranslationUnitCursor(tu->unit))
    ast->dump()
end sub
