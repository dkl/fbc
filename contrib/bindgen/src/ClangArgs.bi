#pragma once

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
