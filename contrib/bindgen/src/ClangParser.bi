#pragma once
#include once "AstNode.bi"
#include once "ClangContext.bi"
#include once "HashTable.bi"

type TempIdProvider
    count as uinteger
    declare function getNext() as string
end type

'' A forward-referenced or defined type.
'' Forward-referenced types can eventually turn into defined ones.
type TypeNode
    usr as string
    id as string
    forwardid as string
    was_forward_used as boolean
    was_defined as boolean
end type

type TypeAddResult
    t as const TypeNode ptr
    emit_forward_decl as boolean
    is_duplicated_decl as boolean
end type

type TypeTable
    hashtb as HashTable = HashTable(8) '' map clang USR string (owned by TypeNode) => TypeNode ptr
    tempid as TempIdProvider

    declare constructor()
    declare destructor()
    declare operator let(byref as const TypeTable) '' unimplemented

    '' Update the list with a type reference or definition.
    '' If the type is not yet known, this can be a forward-reference or definition.
    '' If the type is already known, this can be a reference or forward-reference.
    declare function add(byval decl as CXCursor, byval is_definition as boolean) as TypeAddResult
end type

type TUParser extends ClangAstVisitor
    logger as ErrorLogger ptr
    tu as ClangTU ptr

    types as TypeTable
    ast as AstNode ptr

    declare constructor(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    declare operator let(byref as const TUParser) '' unimplemented
    declare destructor()

    declare sub emitForwardDecl(byref id as const string, byref forwardid as const string)
    declare const function buildTypeRef(byref id as const string) as FullType

    declare const sub checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    declare const sub checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    declare const function parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    declare const function parseSimpleType(byval ty as CXType) as TypeKind
    declare const function parseCallConv(byval ty as CXType) as ProcCallConv
    declare function parseFunctionType(byval ty as CXType) as FullType
    declare function parseType(byval ty as CXType) as FullType

    declare function parseEnumConstValue(byval cursor as CXCursor, byval parent as CXCursor) as ConstantValue
    declare const function parseEvalResult(byval eval as CXEvalResult) as ConstantValue
    declare const function evaluateInitializer(byval cursor as CXCursor) as ConstantValue

    declare sub parseVarDecl(byval cursor as CXCursor)
    declare sub parseProcDecl(byval cursor as CXCursor)
    declare sub parseRecordDecl(byval cursor as CXCursor, byref id as const string)
    declare sub parseEnumDecl(byval cursor as CXCursor, byref id as const string)
    declare sub parseTagDecl(byval cursor as CXCursor)
    declare sub parseTypedefDecl(byval cursor as CXCursor)

    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
    declare sub parse()
end type
