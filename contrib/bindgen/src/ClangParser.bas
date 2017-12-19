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

function TUParser.visitor(byval cursor as CXCursor, byval parent as CXCursor) as CXChildVisitResult
    select case clang_getCursorKind(cursor)
    case CXCursor_VarDecl
        var n = new AstNode(AstKind_Var)
        n->sym.id = wrapstr(clang_getCursorSpelling(cursor))
        n->sym.t = parseType(clang_getCursorType(cursor))

        if clang_getCursorLinkage(cursor) = CXLinkage_External then
            n->sym.is_extern = true
        end if

        select case clang_Cursor_getStorageClass(cursor)
        case CX_SC_None, CX_SC_Static
            n->sym.is_defined = true
        end select

        ast->append(n)

    case CXCursor_FunctionDecl
        var functiontype = parseType(clang_getCursorType(cursor))
        assert(functiontype.dtype.basetype() = Type_Proc andalso _
               functiontype.subtype andalso _
               functiontype.subtype->kind = AstKind_Proc)

        var n = functiontype.subtype
        functiontype.subtype = NULL
        n->sym.id = wrapstr(clang_getCursorSpelling(cursor))

        ast->append(n)

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
