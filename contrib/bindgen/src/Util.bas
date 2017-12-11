#include once "Util.bi"

sub abortProgram(byref message as const string)
    print "error: " + message
    end 1
end sub
