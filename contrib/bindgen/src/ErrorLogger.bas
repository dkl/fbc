#include once "ErrorLogger.bi"

constructor ErrorLogger()
    stderr_filenum = freefile()
    if open err(for output, as #stderr_filenum) <> 0 then
        stderr_filenum = -1
    end if
end constructor

destructor ErrorLogger()
    if stderr_filenum >= 0 then
        close #stderr_filenum
    end if
end destructor

sub ErrorLogger.eprint(byref message as const string)
    print #stderr_filenum, message
end sub

sub ErrorLogger.printError(byref message as const string)
    eprint("error: " + message)
    have_errors = true
end sub

sub ErrorLogger.abortProgram(byref message as const string)
    printError(message)
    end 1
end sub

sub ErrorLogger.assertOrAbort(byval condition as boolean, byref message as const string)
    if condition = false then
        abortProgram(message)
    end if
end sub

const function ErrorLogger.haveErrors() as boolean
    return have_errors
end function
