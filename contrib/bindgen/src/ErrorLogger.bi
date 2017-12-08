type ErrorLogger
private:
    stderr_filenum as integer
public:
    declare constructor()
    declare constructor(byref as const ErrorLogger) '' unimplemented
    declare operator let(byref as const ErrorLogger) '' unimplemented
    declare destructor()
    declare const sub printError(byref message as const string)
end type
