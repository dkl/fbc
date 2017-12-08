#include once "ClangAstVisitor.bi"

function ClangAstVisitor.staticVisitor(byval cursor as CXCursor, byval parent as CXCursor, byval client_data as CXClientData) as CXChildVisitResult
    dim self as ClangAstVisitor ptr = client_data
    return self->visitor(cursor, parent)
end function

sub ClangAstVisitor.visitChildrenOf(byval cursor as CXCursor)
    clang_visitChildren(cursor, @staticVisitor, @this)
end sub
