#include once "ClangParser.bi"
#include once "Util.bi"

function TempIdProvider.getNext() as string
    function = "__fbbindgen_tempid_" & count
    count += 1
end function

constructor TagNode(byref usr as const string)
    cast(string, this.usr) = usr
end constructor

const function TagNode.getFbForwardId() as string
    if len(id) > 0 then
        return "__fbbindgen_forwardid_" + id
    end if
    return ""
end function

const function TagNode.getFbTypeBlockId() as string
    if is_forward_decl_emitted then
        return getFbForwardId()
    end if
    return id
end function

constructor TagTable()
end constructor

destructor TagTable()
    for i as integer = 0 to hashtb.room - 1
        with hashtb.items[i]
            if .s then
                delete cptr(TagNode ptr, .data)
                .s = NULL
                .data = NULL
            end if
        end with
    next
end destructor

function TagTable.add(byval decl as CXCursor) as TagNode ptr
    var usr = wrapstr(clang_getCursorUSR(decl))

    assert(len(usr) > 0)
    var usrhash = hashHash(usr)
    var item = hashtb.lookup(usr, usrhash)

    if item->s then
        '' Already exists
        return item->data
    end if

    '' New tag
    var tag = new TagNode(usr)
    hashtb.add(item, usrhash, tag->usr, tag)
    return tag
end function

constructor TUParser(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    this.logger = logger
    this.tu = tu
    ast = new AstNode(AstKind_Group)
end constructor

destructor TUParser()
    delete ast
end destructor

sub TUParser.emitForwardDecl(byref id as const string, byref forwardid as const string)
    var n = new AstNode(AstKind_Typedef)
    n->sym.id = id
    n->sym.t = buildTypeRef(forwardid)
    ast->append(n)
end sub

const function TUParser.buildTypeRef(byref id as const string) as FullType
    var typeref = new AstNode(AstKind_TypeRef)
    typeref->sym.id = id
    return FullType(DataType(Type_Named), typeref)
end function

const function TUParser.getSizeOfType(byval ty as CXType) as ulongint
    var size = clang_Type_getSizeOf(ty)
    logger->assertOrAbort(size >= 0, "cannot get sizeof type " + tu->dumpType(ty))
    return size
end function

const sub TUParser.checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    logger->assertOrAbort(condition, _
        "sizeof " + wrapstr(clang_getTypeSpelling(ty)) + _
        " is " & clang_Type_getSizeOf(ty) & " bytes, " + _
        "expected " + expected)
end sub

const sub TUParser.checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    checkBasicTypeSize(getSizeOfType(ty) = expected, ty, str(expected))
end sub

const function TUParser.parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    select case getSizeOfType(ty)
    case 1
        return iif(is_signed, Type_Int8, Type_Uint8)
    case 2
        return iif(is_signed, Type_Int16, Type_Uint16)
    case 4
        return iif(is_signed, Type_Int32, Type_Uint32)
    case 8
        return iif(is_signed, Type_Int64, Type_Uint64)
    case else
        checkBasicTypeSize(false, ty, "1, 2, 4 or 8")
    end select
end function

const function TUParser.parseSimpleType(byval ty as CXType) as TypeKind
    select case as const ty.kind
    case CXType_Void
        return Type_Void

    case CXType_Bool
        '' TODO: Use FB boolean? It's supposed to be ABI-compatible to GCC's _Bool afterall...
        checkBasicTypeSize(ty, 1)
        return Type_Uint8

    case CXType_Char_S, CXType_SChar, _
         CXType_Short, CXType_Int, CXType_Long, CXType_LongLong
        return parseIntType(ty, true)

    case CXType_Char_U, CXType_UChar, _
         CXType_UShort, CXType_UInt, CXType_ULong, CXType_ULongLong
        return parseIntType(ty, false)

    case CXType_Float
        checkBasicTypeSize(ty, 4)
        return Type_Float32

    case CXType_Double
        checkBasicTypeSize(ty, 8)
        return Type_Float64

    case CXType_LongDouble
        return Type_CLongDouble

    end select

    return Type_None
end function

const function TUParser.parseCallConv(byval ty as CXType) as ProcCallConv
    var callconv = clang_getFunctionTypeCallingConv(ty)
    select case callconv
    case CXCallingConv_C
        return CallConv_Cdecl
    case CXCallingConv_X86StdCall
        return CallConv_Stdcall
    case else
        logger->abortProgram("Unsupported callconv " & callconv)
    end select
end function

function TUParser.parseFunctionType(byval ty as CXType) as FullType
    var proc = new AstNode(AstKind_Proc)
    proc->sym.t = parseType(clang_getResultType(ty), false)
    proc->sym.callconv = parseCallConv(ty)

    var paramcount = clang_getNumArgTypes(ty)
    if paramcount > 0 then
        for i as integer = 0 to paramcount - 1
            var param = new AstNode(AstKind_ProcParam)
            param->sym.t = parseType(clang_getArgType(ty, i), false)
            proc->append(param)
        next
    end if

    proc->sym.is_variadic = clang_isFunctionTypeVariadic(ty)

    return FullType(DataType(Type_Proc), proc)
end function

function TUParser.parseType(byval ty as CXType, byval context_allows_using_forward_ref as boolean) as FullType
    '' Resolve typedefs and some unexposed wrapper types
    ty = clang_getCanonicalType(ty)

    dim t as FullType

    select case as const ty.kind
    case CXType_Pointer
        t = parseType(clang_getPointeeType(ty), true)

        if t.arraydims.empty() = false then
            '' Pointer to array - not possible in FB.
            '' Drop the array type, and use a pointer to just one array element.
            t.arraydims = type<ArrayDimensions>()
        end if

        t.dtype = t.dtype.addrOf()

    case CXType_FunctionProto
        t = parseFunctionType(ty)

    case CXType_Unexposed
        var resultty = clang_getResultType(ty)
        if resultty.kind <> CXType_Invalid then
            t = parseFunctionType(ty)
        else
            logger->abortProgram("unhandled clang type " + tu->dumpType(ty))
        end if

    case CXType_Elaborated, CXType_Typedef
        t = parseType(ty, context_allows_using_forward_ref)

    case CXType_Record, CXType_Enum
        var decl = clang_getTypeDeclaration(ty)
        var tag = parseTagDecl(decl, context_allows_using_forward_ref)
        t = buildTypeRef(tag->id)

    case CXType_ConstantArray, CXType_IncompleteArray
        t = parseType(clang_getArrayElementType(ty), false)
        t.arraydims.addOuterDimension(iif(ty.kind = CXType_IncompleteArray, 0, clang_getArraySize(ty)))

    case else
        t.dtype = DataType(parseSimpleType(ty))
        if t.dtype.basetype() = Type_None then
            logger->abortProgram("unhandled clang type " + tu->dumpType(ty))
        end if
    end select

    if clang_isConstQualifiedType(ty) then
        t.dtype.setConst()
    end if

    return t
end function

function TUParser.parseEnumConstValue(byval cursor as CXCursor, byval parent as CXCursor) as ConstantValue
    var t = parseType(clang_getEnumDeclIntegerType(parent), false)
    assert(t.subtype = NULL)

    dim v as ConstantValue
    v.dtype = t.dtype

    if v.dtype.isSignedInteger() then
        v.value = str(clang_getEnumConstantDeclValue(cursor))
    elseif v.dtype.isUnsignedInteger() then
        v.value = str(clang_getEnumConstantDeclUnsignedValue(cursor))
    else
        assert(false)
    end if

    return v
end function

const function TUParser.parseEvalResult(byval eval as CXEvalResult) as ConstantValue
    dim v as ConstantValue
    var evalkind = clang_EvalResult_getKind(eval)
    select case as const evalkind
    case CXEval_Int
        if clang_EvalResult_isUnsignedInt(eval) then
            v.dtype = DataType(Type_UInt64)
            v.value = str(clang_EvalResult_getAsUnsigned(eval))
        else
            v.dtype = DataType(Type_Int64)
            v.value = str(clang_EvalResult_getAsLongLong(eval))
        end if
    case CXEval_Float
        v.dtype = DataType(Type_Float64)
        v.value = str(clang_EvalResult_getAsDouble(eval))
    case CXEval_UnExposed
        '' No initializer
    case else
        logger->abortProgram("unhandled eval result kind " & evalkind)
    end select
    return v
end function

const function TUParser.evaluateInitializer(byval cursor as CXCursor) as ConstantValue
    var eval = clang_Cursor_Evaluate(cursor)
    var v = parseEvalResult(eval)
    clang_EvalResult_dispose(eval)
    return v
end function

sub TUParser.parseVarDecl(byval cursor as CXCursor)
    var n = new AstNode(AstKind_Var)
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    n->sym.t = parseType(clang_getCursorType(cursor), false)
    n->sym.constval = evaluateInitializer(cursor)
    if clang_getCursorLinkage(cursor) = CXLinkage_External then
        n->sym.is_extern = true
    end if
    select case clang_Cursor_getStorageClass(cursor)
    case CX_SC_None, CX_SC_Static
        n->sym.is_defined = true
    end select
    ast->append(n)
end sub

sub TUParser.parseProcDecl(byval cursor as CXCursor)
    var functiontype = parseType(clang_getCursorType(cursor), false)
    assert(functiontype.dtype.basetype() = Type_Proc andalso _
           functiontype.subtype andalso _
           functiontype.subtype->kind = AstKind_Proc)
    var n = functiontype.subtype
    functiontype.subtype = NULL
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    ast->append(n)
end sub

type RecordFieldCollector extends ClangFieldVisitor
    fields(any) as CXCursor
    declare function visitor(byval cursor as CXCursor) as CXVisitorResult override
end type

function RecordFieldCollector.visitor(byval cursor as CXCursor) as CXVisitorResult
    assert(clang_getCursorKind(cursor) = CXCursor_FieldDecl)
    redim preserve fields(0 to ubound(fields) + 1)
    fields(ubound(fields)) = cursor
    return CXChildVisit_Continue
end function

function TUParser.parseFieldDecl(byval cursor as CXCursor) as AstNode ptr
    var id = wrapstr(clang_getCursorSpelling(cursor))
    var ty = clang_getCursorType(cursor)

    if len(id) = 0 then
        var recorddecl = clang_getTypeDeclaration(ty)
        select case clang_getCursorKind(recorddecl)
        case CXCursor_StructDecl, CXCursor_UnionDecl
            if len(wrapstr(clang_getCursorSpelling(recorddecl))) = 0 then
                '' Anonymous struct/union field
                var tag = tags.add(recorddecl)
                return parseRecordDecl(tag, recorddecl)
            end if
        end select
    end if

    var n = new AstNode(AstKind_Field)
    n->sym.id = id
    n->sym.t = parseType(ty, false)
    return n
end function

function TUParser.parseRecordDecl(byval tag as const TagNode ptr, byval cursor as CXCursor) as AstNode ptr
    var n = new AstNode(iif(clang_getCursorKind(cursor) = CXCursor_UnionDecl, AstKind_Union, AstKind_Struct))
    dim fields as RecordFieldCollector
    fields.visitFieldsOf(clang_getCursorType(cursor))
    for i as integer = 0 to ubound(fields.fields)
        n->append(parseFieldDecl(fields.fields(i)))
    next
    return n
end function

type EnumConstCollector extends ClangAstVisitor
    enumconsts(any) as CXCursor
    declare function visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult override
end type

function EnumConstCollector.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    if clang_getCursorKind(cursor) = CXCursor_EnumConstantDecl then
        redim preserve enumconsts(0 to ubound(enumconsts) + 1)
        enumconsts(ubound(enumconsts)) = cursor
    end if
    return CXChildVisit_Continue
end function

function TUParser.parseEnumDecl(byval tag as const TagNode ptr, byval cursor as CXCursor) as AstNode ptr
    var n = new AstNode(AstKind_Enum)
    dim enumconsts as EnumConstCollector
    enumconsts.visitChildrenOf(cursor)
    for i as integer = 0 to ubound(enumconsts.enumconsts)
        var enumconstcursor = enumconsts.enumconsts(i)
        var enumconst = new AstNode(AstKind_EnumConst)
        enumconst->sym.id = wrapstr(clang_getCursorSpelling(enumconstcursor))
        enumconst->sym.constval = parseEnumConstValue(enumconstcursor, cursor)
        n->append(enumconst)
    next
    return n
end function

function TUParser.parseTagDecl(byval cursor as CXCursor, byval context_allows_using_forward_ref as boolean) as const TagNode ptr
    '' Try to resolve the type reference to the definition
    scope
        var def = clang_getCursorDefinition(cursor)
        if clang_isInvalid(clang_getCursorKind(def)) = false then
            cursor = def
        end if
    end scope

    var tag = tags.add(cursor)
    if len(tag->id) = 0 then
        tag->id = wrapstr(clang_getCursorSpelling(cursor))
        if len(tag->id) = 0 then
            tag->id = tempids.getNext()
        end if
    end if

    '' Already emitted previously?
    if tag->is_emitted then
        return tag
    end if

    '' Unresolved forward reference?
    '' Requires special handling since there is no struct/union/enum to parse in this case.
    if clang_isCursorDefinition(cursor) = false then
        emitForwardDecl(tag->id, tag->getFbForwardId())
        tag->is_forward_decl_emitted = true
        tag->is_emitted = true
        return tag
    end if

    '' Already in process of being emitted?
    '' This means there is a circular dependency with another struct/union.
    '' One of the references must be a pointer though, because structs cannot contain each-other,
    '' so this can always be solved by using a forward reference.
    if tag->is_being_emitted then
        if context_allows_using_forward_ref then
            if tag->is_forward_decl_emitted = false then
                emitForwardDecl(tag->id, tag->getFbForwardId())
                tag->is_forward_decl_emitted = true
            end if
            return tag
        end if
        '' TODO: handle infinite recursion that can't be resolved with FB forward refs
        '' (C allows forward refs in more places than FB, e.g. function pointer result types)
    end if

    tag->is_being_emitted = true

    '' Recursively parse the tag, and emit the types needed by the fields.
    dim n as AstNode ptr
    if clang_getCursorKind(cursor) = CXCursor_EnumDecl then
        n = parseEnumDecl(tag, cursor)
    else
        n = parseRecordDecl(tag, cursor)
    end if

    n->sym.id = tag->getFbTypeBlockId()
    n->sym.size = getSizeOfType(clang_getCursorType(cursor))

    if tag->is_emitted then
        '' Already emitted now due to recursion, don't emit again.
        delete n
        n = NULL
    else
        ast->append(n)
        tag->is_emitted = true
    end if

    tag->is_being_emitted = false
    return tag
end function

sub TUParser.parseTypedefDecl(byval cursor as CXCursor)
    var n = new AstNode(AstKind_Typedef)
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    n->sym.t = parseType(clang_getTypedefDeclUnderlyingType(cursor), true)
    ast->append(n)
end sub

function TUParser.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    select case as const clang_getCursorKind(cursor)
    case CXCursor_VarDecl
        parseVarDecl(cursor)

    case CXCursor_FunctionDecl
        parseProcDecl(cursor)

    case CXCursor_StructDecl, CXCursor_UnionDecl, CXCursor_EnumDecl
        '' Most tags (including anonymous ones) are parsed by parseType() when needed,
        '' but we also want to collect unused global named tags, so the types are available in
        '' the binding.
        parseTagDecl(cursor, true)

        '' Recurse into tag body, which may contain nested named tag declarations
        return CXChildVisit_Recurse

    case CXCursor_TypedefDecl
        parseTypedefDecl(cursor)

    case CXCursor_MacroDefinition
        '' TODO

    case CXCursor_InclusionDirective, CXCursor_MacroExpansion
        '' Ignore

    case CXCursor_EnumConstantDecl, CXCursor_FieldDecl
        '' Ignore, should only occur during recursion

    case else
        logger->abortProgram("unhandled cursor kind: " + wrapstr(clang_getCursorKindSpelling(clang_getCursorKind(cursor))))
    end select

    return CXChildVisit_Continue
end function

sub TUParser.parse()
    visitChildrenOf(clang_getTranslationUnitCursor(tu->unit))
end sub
