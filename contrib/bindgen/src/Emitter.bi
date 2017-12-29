#include once "AstNode.bi"

type Emitter
private:
    indent as integer

public:
    declare function emitType(byref t as const FullType) as string
    declare function emitConstVal(byref v as const ConstantValue) as string
    declare sub emitAlias(byref s as string, byval n as const AstNode ptr)
    declare sub emitArrayDimensions(byref s as string, byref arraydims as const ArrayDimensions)
    declare function emitIdAndArray(byval n as const AstNode ptr) as string
    declare function emitCommaSeparatedChildren(byval n as const AstNode ptr) as string
    declare function emitProcParam(byval n as const AstNode ptr) as string
    declare function emitProcParams(byval n as const AstNode ptr) as string
    declare function emitProcHeader(byval n as const AstNode ptr) as string

    declare sub emitLine(byref ln as const string)
    declare sub emitIndentedChildren(byval n as const AstNode ptr)
    declare function emitInitializer(byval n as const AstNode ptr) as string
    declare sub emitVarDecl(byref keyword as const string, byval n as const AstNode ptr)
    declare sub emitCompoundHeader(byval n as const AstNode ptr)
    declare sub emitCompoundFooter(byval n as const AstNode ptr)
    declare sub emitDecl(byval n as const AstNode ptr)
    declare sub emitBinding(byval n as const AstNode ptr)
end type
