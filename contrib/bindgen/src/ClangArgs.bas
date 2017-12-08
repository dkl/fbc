#include once "ClangArgs.bi"

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
