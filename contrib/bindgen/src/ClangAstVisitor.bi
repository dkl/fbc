#pragma once
#include once "ClangContext.bi"

type ClangAstVisitor extends object
    declare abstract function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    declare static function staticVisitor(byval cursor as CXCursor, byval parent as CXCursor, byval client_data as CXClientData) as CXChildVisitResult
    declare sub visitChildrenOf(byval cursor as CXCursor)
end type
