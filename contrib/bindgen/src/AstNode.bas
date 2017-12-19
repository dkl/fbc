#include once "AstNode.bi"
#include once "Util.bi"

constructor DataType()
    bits = Type_None
end constructor

constructor DataType(byval t as TypeKind)
    bits = t
end constructor

constructor DataType(byval bits as ulong)
    this.bits = bits
end constructor

const function DataType.withBase(byval ty as TypeKind) as DataType
    return DataType((bits and (not Mask_Base)) or (culng(ty) and Mask_Base))
end function

const function DataType.withConst() as DataType
    return DataType(bits or (1ul shl Pos_Const))
end function

const function DataType.withRef() as DataType
    return DataType(bits or (1ul shl Pos_Ref))
end function

const function DataType.withoutBaseConst() as DataType
    return DataType(bits and (not (1ul shl (Pos_Const + ptrcount()))))
end function

const function DataType.withoutConsts() as DataType
    return DataType(bits and (Mask_Base or Mask_Ptr))
end function

const function DataType.addrOf(byval ptrlevels as uinteger) as DataType
    if ptrcount() + ptrlevels > MaxPtrCount then
        return DataType(Type_None)
    end if
    return DataType(((bits and (Mask_Base or Mask_Ref)) or _
                     ((bits and Mask_Ptr) + (ptrlevels shl Pos_Ptr)) or _
                     ((bits and Mask_Const) shl ptrlevels)))
end function

const function DataType.expand(byval other as DataType) as DataType
    var thisptrcount = ptrcount()
    if thisptrcount + other.ptrcount() > MaxPtrCount then
        return DataType(Type_None)
    end if
    if isRef() and other.isRef() then
        return DataType(Type_None)
    end if
    return DataType(other.addrOf(thisptrcount).bits or (bits and (Mask_Const or Mask_Ref)))
end function

const function DataType.isConstAt(byval ptrlevel as uinteger) as boolean
    return ((bits and (1ul shl (Pos_Const + ptrlevel))) <> 0)
end function

const function DataType.isRef() as boolean
    return ((bits and Mask_Ref) <> 0)
end function

const function DataType.basetype() as TypeKind
    return bits and Mask_Base
end function

const function DataType.ptrcount() as uinteger
    return (bits and Mask_Ptr) shr Pos_Ptr
end function

sub DataType.setConst()
    this = withConst()
end sub

dim shared TypeNames(0 to TypeCount - 1) as const zstring const ptr => { _
    @"none"    , _
    @"void"    , _
    @"int8"    , _
    @"int16"   , _
    @"int32"   , _
    @"int64"   , _
    @"intptr"  , _
    @"uint8"   , _
    @"uint16"  , _
    @"uint32"  , _
    @"uint64"  , _
    @"uintptr" , _
    @"float32" , _
    @"float64" , _
    @"clongdouble", _
    @"named"   , _
    @"proc"    , _
    @"char"    , _
    @"zstring" , _
    @"wchar"   , _
    @"wstring" , _
    @"array"     _
}

const function DataType.dump() as string
    dim s as string

    if isRef() then
        s += "byref "
    end if

    if isConstAt(ptrcount()) then
        s += "const "
    end if

    s += *TypeNames(basetype())

    if ptrcount() > 0 then
        for i as integer = (ptrcount() - 1) to 0 step -1
            if isConstAt(i) then
                s += " const"
            end if
            s += " ptr"
        next
    end if

    return s
end function

constructor FullType()
end constructor

constructor FullType(byval dtype as DataType)
    this.dtype = dtype
end constructor

constructor FullType(byval dtype as DataType, byval subtype as AstNode ptr)
    this.dtype = dtype
    this.subtype = subtype
end constructor

constructor FullType(byref other as const FullType)
    this = other
end constructor

operator FullType.let(byref other as const FullType)
    dtype = other.dtype
    delete subtype
    subtype = NULL
    if other.subtype then
        subtype = new AstNode(*other.subtype)
    end if
end operator

destructor FullType()
    delete subtype
end destructor

constructor AstNode(byval kind as AstKind)
    this.kind = kind
end constructor

constructor AstNode(byref other as const AstNode)
    this = other
end constructor

operator AstNode.let(byref other as const AstNode)
    kind = other.kind
    sym = other.sym
    removeAll()
    dim as AstNode ptr i = other.head
    while i
        append(new AstNode(*i))
        i = i->nxt
    wend
end operator

destructor AstNode()
    removeAll()
end destructor

const function AstNode.getIndexOf(byval n as AstNode ptr) as integer
    var index = 0
    dim as AstNode ptr i = head
    while i
        if i = n then
            return index
        end if
        index += 1
        i = i->nxt
    wend
    function = -1
end function

const function AstNode.contains(byval n as AstNode ptr) as boolean
    return (getIndexOf(n) >= 0)
end function

sub AstNode.insert(byval n as AstNode ptr, byval ref as AstNode ptr)
    assert(not contains(n))
    if ref then
        assert(contains(ref))
        if ref->prev then
            ref->prev->nxt = n
            n->prev = ref->prev
        else
            head = n
            assert(n->prev = NULL)
        end if
        n->nxt = ref
        ref->prev = n
    else
        if tail then
            tail->nxt = n
            n->prev = tail
        else
            head = n
            assert(n->prev = NULL)
        end if
        assert(n->nxt = NULL)
        tail = n
    end if
end sub

sub AstNode.prepend(byval n as AstNode ptr)
    insert(n, head)
end sub

sub AstNode.append(byval n as AstNode ptr)
    insert(n, NULL)
end sub

sub AstNode.unlink(byval n as AstNode ptr)
    assert(contains(n))
    if n->prev then
        n->prev->nxt = n->nxt
    else
        assert(head = n)
        head = n->nxt
    end if
    if n->nxt then
        n->nxt->prev = n->prev
    else
        assert(tail = n)
        tail = n->prev
    end if
    n->prev = NULL
    n->nxt = NULL
end sub

function AstNode.remove(byval n as AstNode ptr) as AstNode ptr
    function = n->nxt
    unlink(n)
    delete n
end function

sub AstNode.removeAll()
    while head
        remove(head)
    wend
end sub

dim shared as const zstring const ptr AstKindNames(0 to AstKindCount - 1) => { _
    @"group"      , _
    @"const"      , _
    @"var"        , _
    @"enum"       , _
    @"enumconst"  , _
    @"typedef"    , _
    @"struct"     , _
    @"union"      , _
    @"field"      , _
    @"proc"       , _
    @"procparam"  , _
    @"macro"      , _
    @"macroparam" , _
    @"externbegin", _
    @"externend"    _
}

const function AstNode.dumpOne() as string
    var s = *AstKindNames(kind)
    if len(sym.id) > 0 then
        s += " " + sym.id
    end if
    if len(sym.aliasid) > 0 then
        s += " alias """ + sym.aliasid + """"
    end if
    if sym.t.dtype.basetype() <> Type_None then
        s += " as " + sym.t.dtype.dump()
    end if
    return s
end function

const sub AstNode.dump(byref logger as ErrorLogger, byval nestlevel as integer, byref prefix as const string)
    nestlevel += 1

    scope
        var s = space((nestlevel - 1) * 4)
        if len(prefix) > 0 then
            s += prefix + ": "
        end if
        s += dumpOne()
        logger.eprint(s)
    end scope

    if sym.t.subtype then
        sym.t.subtype->dump(logger, nestlevel, "subtype")
    end if

    dim i as const AstNode ptr = head
    while i
        i->dump(logger, nestlevel)
        i = i->nxt
    wend

    nestlevel -= 1
end sub
