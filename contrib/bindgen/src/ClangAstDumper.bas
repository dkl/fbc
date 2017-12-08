#include once "ClangAstDumper.bi"
#include once "ClangStr.bi"

private function dumpSourceLocation(byval location as CXSourceLocation) as string
    dim filename as CXString
    dim as ulong linenum, column
    clang_getPresumedLocation(location, @filename, @linenum, @column)
    function = *clang_getCString(filename) + ":" & linenum & ":" & column
    clang_disposeString(filename)
end function

private function dumpClangType(byval ty as CXType) as string
    var s = wrapstr(clang_getTypeKindSpelling(ty.kind)) + " " + wrapstr(clang_getTypeSpelling(ty))

    select case ty.kind
    case CXType_Elaborated
        s += " elaborated " + dumpClangType(clang_Type_getNamedType(ty))
    end select

    var canonical = clang_getCanonicalType(ty)
    if clang_equalTypes(ty, canonical) = 0 then
        s += " canonical " + dumpClangType(canonical)
    end if

    return s
end function

private function dumpCursor(byval cursor as CXCursor) as string
    var s = wrapstr(clang_getCursorKindSpelling(clang_getCursorKind(cursor)))
    s += " " + wrapstr(clang_getCursorSpelling(cursor))
    s += " | type " + dumpClangType(clang_getCursorType(cursor))
    s += " | source " + dumpSourceLocation(clang_getCursorLocation(cursor))
    return s
end function

constructor ClangAstDumper(byref ctx as ClangContext)
    this.ctx = @ctx
end constructor

function ClangAstDumper.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    dump(cursor)
    return CXChildVisit_Continue
end function

sub ClangAstDumper.dump(byval cursor as CXCursor)
    print space(nestinglevel * 4) + dumpCursor(cursor)
    nestinglevel += 1
    visitChildrenOf(cursor)
    nestinglevel -= 1
end sub

sub ClangAstDumper.dump()
    dump(clang_getTranslationUnitCursor(ctx->unit))
end sub
