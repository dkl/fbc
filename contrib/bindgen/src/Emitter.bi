#include once "AstNode.bi"

type Emitter
private:
    indent as integer

public:
    declare function emitType(byref t as const FullType) as string
    declare function emitAlias(byval n as const AstNode ptr) as string
    declare function emitIdAndArray(byval n as const AstNode ptr) as string
    declare function emitCommaSeparatedChildren(byval n as const AstNode ptr) as string
    declare function emitProcParam(byval n as const AstNode ptr) as string
    declare function emitProcParams(byval n as const AstNode ptr) as string
    declare function emitProcHeader(byval n as const AstNode ptr) as string

    declare sub emitLine(byref ln as const string)
    declare sub emitIndentedChildren(byval n as const AstNode ptr)
    declare sub emitVarDecl(byref keyword as const string, byval n as const AstNode ptr)
    declare sub emitCompoundHeader(byval n as const AstNode ptr)
    declare sub emitCompoundFooter(byval n as const AstNode ptr)
    declare sub emitCode(byval n as const AstNode ptr)
end type
