#pragma once
#include once "ErrorLogger.bi"

enum TypeKind
    Type_None
    Type_Void
    Type_Int8
    Type_Int16
    Type_Int32
    Type_Int64
    Type_IntPtr
    Type_Uint8
    Type_Uint16
    Type_Uint32
    Type_Uint64
    Type_UintPtr
    Type_Float32
    Type_Float64
    Type_CLongDouble
    Type_Named
    Type_Proc
    Type_Char
    Type_Zstring
    Type_Wchar
    Type_Wstring
    Type_Array
    TypeCount
end enum

type DataType
private:
    bits as ulong

    const Mask_Base  = &b00000000000000000000000011111111ul '' 1 byte, enough for TYPE_* enum
    const Mask_Ptr   = &b00000000000000000000111100000000ul '' 0..15, enough for max. 8 PTRs on a type, like FB
    const Mask_Ref   = &b00000000000000000001000000000000ul '' 0..1, reference or not?
    const Mask_Const = &b00000000001111111110000000000000ul '' 1 bit per PTR + 1 for the toplevel

    const Pos_Ptr   = 8 '' bit where PTR mask starts
    const Pos_Ref   = Pos_Ptr + 4
    const Pos_Const = Pos_Ref + 1

public:
    const MaxPtrCount = 8

    declare constructor()
    declare constructor(byval t as TypeKind)
private:
    declare constructor(byval bits as ulong)
public:

    declare const function withBase(byval ty as TypeKind) as DataType
    declare const function withConst() as DataType
    declare const function withRef() as DataType
    declare const function withoutBaseConst() as DataType
    declare const function withoutConsts() as DataType
    declare const function addrOf(byval ptrlevels as uinteger = 1) as DataType

    '' Merge/expand other dtype into this one, overwriting this' base type, but preserving this' ptrs/consts.
    '' This is useful for expanding a typedef into the context of this dtype.
    declare const function expand(byval other as DataType) as DataType

    declare const function isConstAt(byval ptrlevel as uinteger) as boolean
    declare const function isRef() as boolean
    declare const function basetype() as TypeKind
    declare const function ptrcount() as uinteger

    declare sub setConst()

    declare const function dump() as string
end type

type AstNode as AstNode_

type FullType
    dtype as DataType
    subtype as AstNode ptr

    declare constructor()
    declare constructor(byval dtype as DataType)
    declare constructor(byval dtype as DataType, byval subtype as AstNode ptr)
    declare constructor(byref other as const FullType)
    declare operator let(byref other as const FullType)
    declare destructor()
end type

enum ProcCallConv
    CallConv_Cdecl
    CallConv_Stdcall
end enum

type SymbolInfo
    t as FullType

    id as string '' Symbol name
    aliasid as string '' External name (if symbol was renamed, or if given via asm() in C code, etc.)

    callconv as ProcCallConv
    packed : 1 as boolean '' structs
    variadic : 1 as boolean '' functions/macros: implicit variadic parameter at end
    dllimport : 1 as boolean
    functionlike : 1 as boolean '' macros
    is_extern : 1 as boolean '' var
    is_defined : 1 as boolean '' var

    bits as ubyte '' bitfield size
    fieldalign as ubyte '' max pack/field alignment for structs/unions
end type

enum AstKind
    AstKind_Group
    AstKind_Const
    AstKind_Var
    AstKind_Enum
    AstKind_EnumConst
    AstKind_Typedef
    AstKind_Struct
    AstKind_Union
    AstKind_Field
    AstKind_Proc
    AstKind_ProcParam
    AstKind_Macro
    AstKind_MacroParam
    AstKind_ExternBlockBegin
    AstKind_ExternBlockEnd
    AstKindCount
end enum

type AstNode_
    kind as AstKind
    sym as SymbolInfo

    '' Linked list of child nodes: fields/parameters/...
    as AstNode ptr head, tail, nxt, prev

    declare constructor(byval kind as AstKind)
    declare constructor(byref other as const AstNode)
    declare operator let(byref other as const AstNode)
    declare destructor()

    declare const function getIndexOf(byval n as AstNode ptr) as integer

    '' Check whether this list contains the given node (as direct child)
    declare const function contains(byval n as AstNode ptr) as boolean

    '' Insert in front of ref, or append if ref = NULL
    declare sub insert(byval n as AstNode ptr, byval ref as AstNode ptr)

    declare sub prepend(byval n as AstNode ptr)
    declare sub append(byval n as AstNode ptr)

    '' Unlink node from linked list, but don't delete the node
    declare sub unlink(byval n as AstNode ptr)

    '' Unlink and delete
    declare function remove(byval n as AstNode ptr) as AstNode ptr

    declare sub removeAll()

    declare const function dumpOne() as string
    declare const sub dump(byref logger as ErrorLogger, byval nestlevel as integer = 0, byref prefix as const string = "")
end type
