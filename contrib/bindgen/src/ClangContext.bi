#pragma once
#include once "ClangArgs.bi"
#include once "clang-c.bi"
#include once "ErrorLogger.bi"

type ClangContext
    index as CXIndex
    unit as CXTranslationUnit

    declare constructor()
    declare destructor()
    declare operator let(byref as const ClangContext) '' unimplemented

    declare sub parseTranslationUnit(byref logger as ErrorLogger, byref args as const ClangArgs)
end type
