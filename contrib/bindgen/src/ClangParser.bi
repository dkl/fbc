#pragma once
#include once "AstNode.bi"
#include once "ClangContext.bi"

type TUParser extends ClangAstVisitor
    logger as ErrorLogger ptr
    tu as ClangTU ptr
    ast as AstNode ptr

    declare constructor(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    declare operator let(byref as const TUParser) '' unimplemented
    declare destructor()

    declare const sub checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    declare const sub checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    declare const function parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    declare const function parseSimpleType(byval ty as CXType) as TypeKind
    declare const function parseCallConv(byval ty as CXType) as ProcCallConv
    declare const function parseFunctionType(byval ty as CXType) as FullType
    declare const function parseType(byval ty as CXType) as FullType

    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
    declare sub parse()
end type
