#pragma once

#ifndef NULL
    const NULL as any ptr = 0
#endif

declare sub abortProgram(byref message as const string)

#macro assertOrAbort(condition, message)
    if (condition) = 0 then
        abortProgram(message)
    end if
#endmacro
