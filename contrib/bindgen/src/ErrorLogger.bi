type ErrorLogger
private:
    stderr_filenum as integer
public:
    declare constructor()
    declare constructor(byref as const ErrorLogger) '' unimplemented
    declare operator let(byref as const ErrorLogger) '' unimplemented
    declare destructor()
    declare sub eprint(byref message as const string)
    declare sub printError(byref message as const string)
    declare sub abortProgram(byref message as const string)
    declare sub assertOrAbort(byval condition as boolean, byref message as const string)
end type
