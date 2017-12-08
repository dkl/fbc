#pragma once
#include once "clang-c.bi"

type ClangStr
    s as CXString
    declare constructor(byval source as CXString)
    declare constructor(byref as const ClangStr) '' unimplemented
    declare operator let(byref as const ClangStr) '' unimplemented
    declare destructor()
    declare function value() as string
end type

declare function wrapstr(byref s as CXString) as string
