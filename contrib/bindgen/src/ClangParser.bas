#include once "ClangParser.bi"
#include once "Util.bi"

constructor TUParser(byval logger as ErrorLogger ptr, byval tu as ClangTU ptr)
    this.logger = logger
    this.tu = tu
    ast = new AstNode(AstKind_Group)
end constructor

destructor TUParser()
    delete ast
end destructor

const sub TUParser.checkBasicTypeSize(byval condition as boolean, byval ty as CXType, byref expected as const string)
    logger->assertOrAbort(condition, _
        "sizeof " + wrapstr(clang_getTypeSpelling(ty)) + _
        " is " & clang_Type_getSizeOf(ty) & " bytes, " + _
        "expected " + expected)
end sub

const sub TUParser.checkBasicTypeSize(byval ty as CXType, byval expected as uinteger)
    checkBasicTypeSize(clang_Type_getSizeOf(ty) = expected, ty, str(expected))
end sub

const function TUParser.parseIntType(byval ty as CXType, byval is_signed as boolean) as TypeKind
    select case clang_Type_getSizeOf(ty)
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

const function TUParser.parseFunctionType(byval ty as CXType) as FullType
    var proc = new AstNode(AstKind_Proc)
    proc->sym.t = parseType(clang_getResultType(ty))
    proc->sym.callconv = parseCallConv(ty)

    var paramcount = clang_getNumArgTypes(ty)
    if paramcount > 0 then
        for i as integer = 0 to paramcount - 1
            var param = new AstNode(AstKind_ProcParam)
            param->sym.t = parseType(clang_getArgType(ty, i))
            proc->append(param)
        next
    end if

    proc->sym.is_variadic = clang_isFunctionTypeVariadic(ty)

    return FullType(DataType(Type_Proc), proc)
end function

const function TUParser.parseType(byval ty as CXType) as FullType
    dim t as FullType

    select case as const ty.kind
    case CXType_Pointer
        t = parseType(clang_getPointeeType(ty))
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
        t = parseType(clang_getCanonicalType(ty))

    case CXType_Record, CXType_Enum
        var typeref = new AstNode(AstKind_TypeRef)
        typeref->sym.id = wrapstr(clang_getCursorSpelling(clang_getTypeDeclaration(ty)))
        t = FullType(DataType(Type_Named), typeref)

    case else
        t.dtype = t.dtype.withBase(parseSimpleType(ty))
        if t.dtype.basetype() = Type_None then
            logger->abortProgram("unhandled clang type " + tu->dumpType(ty))
        end if
    end select

    if clang_isConstQualifiedType(ty) then
        t.dtype.setConst()
    end if

    return t
end function

const function TUParser.parseEnumConstValue(byval cursor as CXCursor, byval parent as CXCursor) as ConstantValue
    var t = parseType(clang_getEnumDeclIntegerType(parent))
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

const function TUParser.parseVarDecl(byval cursor as CXCursor) as AstNode ptr
    var n = new AstNode(AstKind_Var)
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    n->sym.t = parseType(clang_getCursorType(cursor))
    n->sym.constval = evaluateInitializer(cursor)
    if clang_getCursorLinkage(cursor) = CXLinkage_External then
        n->sym.is_extern = true
    end if
    select case clang_Cursor_getStorageClass(cursor)
    case CX_SC_None, CX_SC_Static
        n->sym.is_defined = true
    end select
    return n
end function

const function TUParser.parseProcDecl(byval cursor as CXCursor) as AstNode ptr
    var functiontype = parseType(clang_getCursorType(cursor))
    assert(functiontype.dtype.basetype() = Type_Proc andalso _
           functiontype.subtype andalso _
           functiontype.subtype->kind = AstKind_Proc)
    var n = functiontype.subtype
    functiontype.subtype = NULL
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    return n
end function

type RecordFieldCollector
    fields(any) as CXCursor
    declare static function staticVisitor(byval cursor as CXCursor, byval client_data as CXClientData) as CXVisitorResult
    declare function visitor(byval cursor as CXCursor) as CXVisitorResult
    declare sub collectFieldsOf(byval ty as CXType)
end type

function RecordFieldCollector.staticVisitor(byval cursor as CXCursor, byval client_data as CXClientData) as CXVisitorResult
    dim self as RecordFieldCollector ptr = client_data
    return self->visitor(cursor)
end function

function RecordFieldCollector.visitor(byval cursor as CXCursor) as CXVisitorResult
    if clang_getCursorKind(cursor) = CXCursor_FieldDecl then
        redim preserve fields(0 to ubound(fields) + 1)
        fields(ubound(fields)) = cursor
    end if
    return CXChildVisit_Continue
end function

sub RecordFieldCollector.collectFieldsOf(byval ty as CXType)
    clang_Type_visitFields(ty, @staticVisitor, @this)
end sub

const function TUParser.parseRecordDecl(byval cursor as CXCursor, byval is_union as boolean) as AstNode ptr
    var record = new AstNode(iif(is_union, AstKind_Union, AstKind_Struct))
    record->sym.id = wrapstr(clang_getCursorSpelling(cursor))

    var ty = clang_getCursorType(cursor)

    dim fields as RecordFieldCollector
    fields.collectFieldsOf(ty)
    for i as integer = 0 to ubound(fields.fields)
        var fld = new AstNode(AstKind_Field)
        fld->sym.id = wrapstr(clang_getCursorSpelling(fields.fields(i)))
        fld->sym.t = parseType(clang_getCursorType(fields.fields(i)))
        record->append(fld)
    next

    return record
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

const function TUParser.parseEnumDecl(byval cursor as CXCursor) as AstNode ptr
    var n = new AstNode(AstKind_Enum)
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))

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

const function TUParser.parseTypedefDecl(byval cursor as CXCursor) as AstNode ptr
    var n = new AstNode(AstKind_Typedef)
    n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
    n->sym.t = parseType(clang_getTypedefDeclUnderlyingType(cursor))
    return n
end function

function TUParser.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    select case clang_getCursorKind(cursor)
    case CXCursor_VarDecl
        ast->append(parseVarDecl(cursor))

    case CXCursor_FunctionDecl
        ast->append(parseProcDecl(cursor))

    case CXCursor_StructDecl
        ast->append(parseRecordDecl(cursor, false))

    case CXCursor_UnionDecl
        ast->append(parseRecordDecl(cursor, true))

    case CXCursor_EnumDecl
        ast->append(parseEnumDecl(cursor))

    case CXCursor_TypedefDecl
        ast->append(parseTypedefDecl(cursor))

    case CXCursor_MacroDefinition
        '' TODO

    case else
        logger->abortProgram("unhandled cursor kind: " + wrapstr(clang_getCursorKindSpelling(clang_getCursorKind(cursor))))
    end select

    return CXChildVisit_Continue
end function

sub TUParser.parse()
    visitChildrenOf(clang_getTranslationUnitCursor(tu->unit))
end sub
