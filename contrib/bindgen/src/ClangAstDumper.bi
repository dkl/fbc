#pragma once
#include once "ClangAstVisitor.bi"

type ClangAstDumper extends ClangAstVisitor
    ctx as ClangContext ptr
    nestinglevel as integer
    declare constructor(byref ctx as ClangContext)
    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
    declare static function dumpOne(byval cursor as CXCursor) as string
    declare sub dump(byval cursor as CXCursor)
    declare sub dump()
end type
