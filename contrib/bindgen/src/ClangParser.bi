#pragma once
#include once "AstNode.bi"
#include once "ClangContext.bi"
#include once "HashTable.bi"

type TempIdProvider
    count as uinteger
    declare function getNext() as string
end type

'' Information about a struct/union/enum tag identifier
type TagNode
    '' clang's unique Unified Symbol Resolution identifier,
    '' used as key for TagTable.hashtb
    usr as const string

    '' struct/union/enum name (original or auto-generated if anonymous),
    '' except for anonymous struct/union field types that will be emitted
    '' as anonymous in the FB code too.
    id as string

    is_emitted as boolean
    is_being_emitted as boolean
    is_forward_decl_emitted as boolean

    declare constructor(byref usr as const string)

    '' Get the FB forward reference id for this type, if any.
    declare const function getFbForwardId() as string

    '' Get the id to use in the FB TYPE..END TYPE definition.
    declare const function getFbTypeBlockId() as string
end type

type TagTable
    hashtb as HashTable = HashTable(8) '' map clang USR string (owned by TypeNode) => TypeNode ptr

    declare constructor()
    declare destructor()
    declare operator let(byref as const TagTable) '' unimplemented

    declare function add(byval decl as CXCursor) as TagNode ptr
end type

type TUParser extends ClangAstVisitor
    logger as ErrorLogger ptr
    tu as ClangTU ptr

    tags as TagTable
    tempids as TempIdProvider
    ast as AstNode ptr

    declare constructor(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    declare operator let(byref as const TUParser) '' unimplemented
    declare destructor()

    declare sub emitForwardDecl(byref id as const string, byref forwardid as const string)
    declare const function buildTypeRef(byref id as const string) as FullType

    declare const function getSizeOfType(byval ty as CXType) as ulongint
    declare const sub checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    declare const sub checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    declare const function parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    declare const function parseSimpleType(byval ty as CXType) as TypeKind
    declare const function parseCallConv(byval ty as CXType) as ProcCallConv
    declare function parseFunctionType(byval ty as CXType) as FullType
    declare function parseType(byval ty as CXType, byval context_allows_using_forward_ref as boolean) as FullType

    declare function parseEnumConstValue(byval cursor as CXCursor, byval parent as CXCursor) as ConstantValue
    declare const function parseEvalResult(byval eval as CXEvalResult) as ConstantValue
    declare const function evaluateInitializer(byval cursor as CXCursor) as ConstantValue

    declare sub parseVarDecl(byval cursor as CXCursor)
    declare sub parseProcDecl(byval cursor as CXCursor)
    declare function parseFieldDecl(byval cursor as CXCursor) as AstNode ptr
    declare function parseRecordDecl(byval tag as const TagNode ptr, byval cursor as CXCursor) as AstNode ptr
    declare function parseEnumDecl(byval tag as const TagNode ptr, byval cursor as CXCursor) as AstNode ptr
    declare function parseTagDecl(byval cursor as CXCursor, byval context_allows_using_forward_ref as boolean) as const TagNode ptr
    declare sub parseTypedefDecl(byval cursor as CXCursor)
    declare sub parseMacro(byval cursor as CXCursor)

    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
    declare sub parse()
end type
