#pragma once
#include once "clang-c.bi"
#include once "ErrorLogger.bi"

type ClangArgs
private:
    strings(any) as const zstring ptr

public:
    declare constructor()
    declare constructor(byref as const ClangArgs) '' unimplemented
    declare operator let(byref as const ClangArgs) '' unimplemented
    declare sub append(byref s as const string)
    declare const function data() as const zstring const ptr ptr
    declare const function size() as uinteger
    declare const function dump() as string
    declare destructor()
end type

type ClangIndex
    index as CXIndex

    declare constructor()
    declare destructor()
    declare operator let(byref as const ClangIndex) '' unimplemented
end type

type ClangTU
    index as ClangIndex
    unit as CXTranslationUnit
    parse_errorcode as CXErrorCode

    declare constructor(byref args as const ClangArgs)
    declare destructor()
    declare operator let(byref as const ClangTU) '' unimplemented

    declare const sub reportErrors(byref logger as ErrorLogger)

    declare const function getTokenSpelling(byval token as CXToken) as string
    declare const function dumpLocation(byval location as CXSourceLocation) as string
    declare const function dumpType(byval ty as CXType) as string
    declare const function dumpCursor(byval cursor as CXCursor) as string
    declare const function isBuiltIn(byval cursor as CXCursor) as boolean
end type

type ClangAstVisitor extends object
    declare abstract function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    declare static function staticVisitor(byval cursor as CXCursor, byval parent as CXCursor, byval client_data as CXClientData) as CXChildVisitResult
    declare sub visitChildrenOf(byval cursor as CXCursor)
end type

type ClangStr
    s as CXString
    declare constructor(byval source as CXString)
    declare constructor(byref as const ClangStr) '' unimplemented
    declare operator let(byref as const ClangStr) '' unimplemented
    declare destructor()
    declare function value() as string
end type

declare function wrapstr(byref s as CXString) as string

type ClangAstDumper extends ClangAstVisitor
    logger as ErrorLogger ptr
    tu as ClangTU ptr
    nestinglevel as integer
    declare constructor(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
    declare static function dumpOne(byval cursor as CXCursor) as string
    declare sub dump(byval cursor as CXCursor)
    declare sub dump()
    declare const function dumpToken(byval token as CXToken) as string
    declare const function dumpCursorTokens(byval cursor as CXCursor) as string
end type
