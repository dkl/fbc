#include once "Emitter.bi"
#include once "Util.bi"

function Emitter.emitType(byref t as const FullType) as string
    dim s as string
    var ptrcount = t.dtype.ptrcount()

    if t.dtype.isConstAt(ptrcount) then
        s += "const "
    end if

    '' If it's a pointer to a function pointer, wrap it inside
    '' a typeof() to prevent the additional PTRs from being seen
    '' as part of the function pointer's result type:
    ''    int (**p)(void)
    ''    p as function() as integer ptr
    ''    p as typeof(function() as integer) ptr
    '' (alternatively a typedef could be used)
    var add_typeof = (t.dtype.basetype() = Type_Proc) and (ptrcount >= 2)
    if add_typeof then
        s += "typeof("
    end if

    select case as const t.dtype.basetype()
    case Type_Void : s += "any"
    case Type_Int8 : s += "byte"
    case Type_Int16 : s += "short"
    case Type_Int32 : s += "long"
    case Type_Int64 : s += "ulongint"
    case Type_IntPtr : s += "integer"
    case Type_Uint8 : s += "ubyte"
    case Type_Uint16 : s += "ushort"
    case Type_Uint32 : s += "ulong"
    case Type_Uint64 : s += "ulongint"
    case Type_UintPtr : s += "uinteger"
    case Type_Float32 : s += "single"
    case Type_Float64 : s += "double"
    case Type_CLongDouble : s += "clongdouble"

    case Type_Named
        assert(t.subtype andalso _
               t.subtype->kind = AstKind_TypeRef andalso _
               len(t.subtype->sym.id) > 0)
        s += t.subtype->sym.id

    case Type_Proc
        if ptrcount >= 1 then
            '' The inner-most PTR on function pointers will be
            '' ignored below, but we still should preserve its CONST
            if t.dtype.isConstAt(ptrcount - 1) then
                s += "const "
            end if
        else
            '' proc type but no pointers -- this is not supported in
            '' place of data types in FB, so here we add a DECLARE to
            '' indicate that it's not supposed to be a procptr type,
            '' but a plain proc type.
            s += "declare "
        end if
        s += emitProcHeader(t.subtype)

    case else
        assert(false)
    end select

    if add_typeof then
        s += ")"
    end if

    '' Ignore most-inner PTR on function pointers -- in FB it's already
    '' implied by writing AS SUB|FUNCTION(...).
    if t.dtype.basetype() = Type_Proc then
        if ptrcount >= 1 then
            ptrcount -= 1
        end if
    end if

    for i as integer = (ptrcount - 1) to 0 step -1
        if t.dtype.isConstAt(i) then
            s += " const"
        end if
        s += " ptr"
    next

    return s
end function

function Emitter.emitConstVal(byref v as const ConstantValue) as string
    dim as string s = v.value
    select case as const v.dtype.basetype()
    case Type_Int8
    case Type_Int16
    case Type_Int32  : s += "l"
    case Type_Int64  : s += "ll"
    case Type_UInt8
    case Type_UInt16
    case Type_Uint32 : s += "ul"
    case Type_Uint64 : s += "ull"
    case Type_Float32 : s += "f"
    case Type_Float64 : s += "d"
    case else
        assert(false)
    end select
    return s
end function

'' Normally we'll emit Extern blocks, making it unnecessary to worry about
'' case-preserving aliases, but symbols can still have an explicit alias set due
'' to symbol renaming.
function Emitter.emitAlias(byval n as const AstNode ptr) as string
    if len(n->sym.aliasid) > 0 then
        return " alias """ + n->sym.aliasid + """"
    end if
    return ""
end function

function Emitter.emitIdAndArray(byval n as const AstNode ptr) as string
    dim s as string = n->sym.id
    '' TODO: array dimensions
    s += emitAlias(n)
    if n->sym.bits > 0 then
        s += " : " & n->sym.bits
    end if
    return s
end function

function Emitter.emitProcParam(byval n as const AstNode ptr) as string
    assert(n->kind = AstKind_ProcParam)
    if n->sym.t.dtype.basetype() = Type_None then
        return "..."
    end if
    dim s as string
    if n->sym.t.dtype.isRef() then
        s += "byref"
    else
        s += "byval"
    end if
    if len(n->sym.id) > 0 then
        s += " " + n->sym.id
    end if
    s += " as " + emitType(n->sym.t)
    return s
end function

function Emitter.emitProcParams(byval proc as const AstNode ptr) as string
    var s = "("

    dim param as const AstNode ptr = proc->head
    while param
        if param <> proc->head then
            s += ", "
        end if
        s += emitProcParam(param)
        param = param->nxt
    wend

    if proc->sym.is_variadic then
        if proc->head then
            s += ", "
        end if
        s += "..."
    end if

    s += ")"
    return s
end function

private function getCallConvKeyword(byval callconv as ProcCallConv) as string
    select case as const callconv
    case CallConv_Cdecl : return "cdecl"
    case CallConv_Stdcall : return "stdcall"
    case else
        assert(false)
    end select
end function

function Emitter.emitProcHeader(byval n as const AstNode ptr) as string
    var is_function = (n->sym.t.dtype.basetype() <> Type_Void)
    var s = iif(is_function, "function", "sub")
    if len(n->sym.id) > 0 then
        s += " " + n->sym.id
    end if
    s += " " + getCallConvKeyword(n->sym.callconv)
    s += emitAlias(n)
    s += emitProcParams(n)
    if is_function then
        s += " as " + emitType(n->sym.t)
    end if
    return s
end function

sub Emitter.emitLine(byref ln as const string)
    print string(indent, !"\t"); ln
end sub

sub Emitter.emitIndentedChildren(byval n as const AstNode ptr)
    indent += 1
    dim i as const AstNode ptr = n->head
    while i
        emitDecl(i)
        i = i->nxt
    wend
    indent -= 1
end sub

function Emitter.emitInitializer(byval n as const AstNode ptr) as string
    if n->sym.constval.dtype.basetype() <> Type_None then
        return " = " + emitConstVal(n->sym.constval)
    end if
    return ""
end function

sub Emitter.emitVarDecl(byref keyword as const string, byval n as const AstNode ptr)
    var ln = keyword + " "
    if n->sym.t.dtype.isRef() then
        ln += "byref "
    end if
    ln += emitIdAndArray(n)
    ln += " as " + emitType(n->sym.t)
    ln += emitInitializer(n)
    emitLine(ln)
end sub

private function getCompoundKeyword(byval n as const AstNode ptr) as string
    select case n->kind
    case AstKind_Struct : return "type"
    case AstKind_Union : return "union"
    case AstKind_Enum : return "enum"
    end select
end function

sub Emitter.emitCompoundHeader(byval n as const AstNode ptr)
    var ln = getCompoundKeyword(n)
    if len(n->sym.id) > 0 then
        ln += " " + n->sym.id
    end if
    if n->sym.fieldalign > 0 then
        ln += " field = " + str(n->sym.fieldalign)
    end if
    emitLine(ln)
end sub

sub Emitter.emitCompoundFooter(byval n as const AstNode ptr)
    emitLine("end " + getCompoundKeyword(n))
end sub

sub Emitter.emitDecl(byval n as const AstNode ptr)
    select case as const n->kind
    case AstKind_Group
        dim i as const AstNode ptr = n->head
        while i
            emitDecl(i)
            i = i->nxt
        wend

    case AstKind_Const
        emitLine("const " + n->sym.id + emitInitializer(n))

    case AstKind_Var
        if n->sym.is_extern then
            emitVarDecl("extern", n)
        end if
        if n->sym.is_defined then
            emitVarDecl("dim shared", n)
        end if

    case AstKind_Struct, AstKind_Union, AstKind_Enum
        emitCompoundHeader(n)
        emitIndentedChildren(n)
        emitCompoundFooter(n)

    case AstKind_Typedef
        emitLine("type " + n->sym.id + " as " + emitType(n->sym.t))

    case AstKind_Field
        '' Fields can be named after keywords, but we have to do
        ''     as type foo
        '' instead of
        ''     foo as type
        '' if foo has special meaning at the beginning of a statement in
        '' a TYPE block.
        emitLine("as " + emitType(n->sym.t) + " " + emitIdAndArray(n))

    case AstKind_EnumConst
        emitLine(n->sym.id + emitInitializer(n))

    case AstKind_Proc
        emitLine("declare " + emitProcHeader(n))

    case AstKind_ExternBlockBegin
        emitLine("extern """ + n->sym.id + """")

    case AstKind_ExternBlockEnd
        emitLine("end extern")

    case else
        assert(false)
    end select
end sub

sub Emitter.emitBinding(byval n as const AstNode ptr)
    emitLine("#include once ""crt/longdouble.bi""")
    emitLine("extern ""C""")
    emitDecl(n)
    emitLine("end extern")
end sub
