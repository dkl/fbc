#include once "ClangContext.bi"
#include once "ClangStr.bi"

constructor ClangContext()
    index = clang_createIndex(0, 0)
end constructor

destructor ClangContext()
    clang_disposeTranslationUnit(unit)
    clang_disposeIndex(index)
end destructor

sub ClangContext.parseTranslationUnit(byref logger as ErrorLogger, byref args as const ClangArgs)
    var e = clang_parseTranslationUnit2(index, _
                NULL, args.data(), args.size(), _
                NULL, 0, _
                CXTranslationUnit_Incomplete, _
                @unit)

    if e <> CXError_Success then
        logger.printError("libclang parsing failed with error code " & e)
        return
    end if

    var diagcount = clang_getNumDiagnostics(unit)
    if diagcount > 0 then
        for i as integer = 0 to diagcount - 1
            logger.printError(ClangStr(clang_formatDiagnostic(clang_getDiagnostic(unit, i), clang_defaultDiagnosticDisplayOptions())).value())
        next
    end if
end sub
