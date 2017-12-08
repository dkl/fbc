#include once "ClangStr.bi"

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
