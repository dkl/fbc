#include once "ClangContext.bi"

constructor ClangArgs()
end constructor

private function strDuplicate(byval s as const zstring ptr) as zstring ptr
    dim as zstring ptr p = callocate(len(*s) + 1)
    *p = *s
    return p
end function

sub ClangArgs.append(byref s as const string)
    redim preserve strings(0 to ubound(strings) + 1)
    strings(ubound(strings)) = strDuplicate(strptr(s))
end sub

const function ClangArgs.data() as const zstring const ptr ptr
    if ubound(strings) < 0 then
        return 0
    end if
    return @strings(0)
end function

const function ClangArgs.size() as uinteger
    return ubound(strings) + 1
end function

const function ClangArgs.dump() as string
    dim s as string
    for i as integer = 0 to ubound(strings)
        if i > 0 then
            s += " "
        end if
        s += *strings(i)
    next
    return s
end function

destructor ClangArgs()
    for i as integer = 0 to ubound(strings)
        deallocate(strings(i))
    next
end destructor

constructor ClangIndex()
    index = clang_createIndex(0, 0)
end constructor

destructor ClangIndex()
    clang_disposeIndex(index)
end destructor

constructor ClangTU(byref args as const ClangArgs)
    parse_errorcode = _
            clang_parseTranslationUnit2(index.index, _
                NULL, args.data(), args.size(), _
                NULL, 0, _
                CXTranslationUnit_Incomplete or CXTranslationUnit_DetailedPreprocessingRecord, _
                @unit)
end constructor

destructor ClangTU()
    clang_disposeTranslationUnit(unit)
end destructor

const sub ClangTU.reportErrors(byref logger as ErrorLogger)
    if parse_errorcode <> CXError_Success then
        logger.printError("libclang parsing failed with error code " & parse_errorcode)
        return
    end if

    var diagcount = clang_getNumDiagnostics(unit)
    if diagcount > 0 then
        for i as integer = 0 to diagcount - 1
            logger.printError(ClangStr(clang_formatDiagnostic(clang_getDiagnostic(unit, i), clang_defaultDiagnosticDisplayOptions())).value())
        next
    end if
end sub

const function ClangTU.getTokenSpelling(byval token as CXToken) as string
    return wrapstr(clang_getTokenSpelling(unit, token))
end function

const function ClangTU.dumpLocation(byval location as CXSourceLocation) as string
    dim filename as CXString
    dim as ulong linenum, column
    clang_getPresumedLocation(location, @filename, @linenum, @column)
    function = *clang_getCString(filename) + ":" & linenum & ":" & column
    clang_disposeString(filename)
end function

const function ClangTU.dumpType(byval ty as CXType) as string
    var s = wrapstr(clang_getTypeKindSpelling(ty.kind)) + " " + wrapstr(clang_getTypeSpelling(ty))

    select case ty.kind
    case CXType_Elaborated
        s += " elaborated " + dumpType(clang_Type_getNamedType(ty))
    end select

    var canonical = clang_getCanonicalType(ty)
    if clang_equalTypes(ty, canonical) = 0 then
        s += " canonical " + dumpType(canonical)
    end if

    return s
end function

const function ClangTU.dumpCursor(byval cursor as CXCursor) as string
    var s = wrapstr(clang_getCursorKindSpelling(clang_getCursorKind(cursor)))
    s += " " + wrapstr(clang_getCursorSpelling(cursor))
    s += " | type " + dumpType(clang_getCursorType(cursor))
    s += " | loc " + dumpLocation(clang_getCursorLocation(cursor))
    return s
end function

const function ClangTU.isBuiltIn(byval cursor as CXCursor) as boolean
    dim file as CXFile
    clang_getSpellingLocation(clang_getCursorLocation(cursor), @file, NULL, NULL, NULL)
    return (file = NULL)
end function

function ClangAstVisitor.staticVisitor(byval cursor as CXCursor, byval parent as CXCursor, byval client_data as CXClientData) as CXChildVisitResult
    dim self as ClangAstVisitor ptr = client_data
    return self->visitor(cursor, parent)
end function

sub ClangAstVisitor.visitChildrenOf(byval cursor as CXCursor)
    clang_visitChildren(cursor, @staticVisitor, @this)
end sub

constructor ClangStr(byval source as CXString)
    s = source
end constructor

destructor ClangStr()
    clang_disposeString(s)
end destructor

function ClangStr.value() as string
    return *clang_getCString(s)
end function

function wrapstr(byref s as CXString) as string
    dim wrapped as ClangStr = ClangStr(s)
    clear(s, 0, sizeof(s))
    return wrapped.value()
end function

constructor ClangAstDumper(byval tu as ClangTU ptr)
    this.tu = tu
end constructor

function ClangAstDumper.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    dump(cursor)
    return CXChildVisit_Continue
end function

sub ClangAstDumper.dump(byval cursor as CXCursor)
    if tu->isBuiltIn(cursor) = false then
        print space(nestinglevel * 4) + tu->dumpCursor(cursor)
    end if
    nestinglevel += 1
    visitChildrenOf(cursor)
    nestinglevel -= 1
end sub

sub ClangAstDumper.dump()
    dump(clang_getTranslationUnitCursor(tu->unit))
end sub

private function dumpTokenKind(byval kind as CXTokenKind) as string
    select case kind
    case CXToken_Comment     : return "Comment"
    case CXToken_Identifier  : return "Identifier"
    case CXToken_Keyword     : return "Keyword"
    case CXToken_Literal     : return "Literal"
    case CXToken_Punctuation : return "Punctuation"
    case else : return "Unknown(" & kind & ")"
    end select
end function

const function ClangAstDumper.dumpToken(byval token as CXToken) as string
    return dumpTokenKind(clang_getTokenKind(token)) + "[" + tu->getTokenSpelling(token) + "]"
end function

const function ClangAstDumper.dumpCursorTokens(byval cursor as CXCursor) as string
    dim buffer as CXToken ptr
    dim count as ulong
    clang_tokenize(tu->unit, clang_getCursorExtent(cursor), @buffer, @count)

    dim s as string
    if count > 0 then
        for i as integer = 0 to count - 1
            if i > 0 then
                s += " "
            end if
            s += dumpToken(buffer[i])
        next
    end if

    clang_disposeTokens(tu->unit, buffer, count)
    return s
end function
