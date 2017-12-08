#include once "ErrorLogger.bi"

constructor ErrorLogger()
    stderr_filenum = freefile()
    if open err(for output, as #stderr_filenum) = 0 then
        stderr_filenum = -1
    end if
end constructor

destructor ErrorLogger()
    if stderr_filenum >= 0 then
        close #stderr_filenum
    end if
end destructor

sub ErrorLogger.printError(byref message as const string)
    print #stderr_filenum, message
end sub
