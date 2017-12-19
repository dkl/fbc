#include once "ClangContext.bi"
#include once "ClangParser.bi"
#include once "Emitter.bi"

type CommandLineOptions
    clangargs as ClangArgs
    show_help as boolean
    show_debug as boolean
    declare sub parse(byval argc as integer, byval argv as const zstring const ptr ptr)
    declare operator let(byref as const CommandLineOptions) '' unimplemented
end type

sub CommandLineOptions.parse(byval argc as integer, byval argv as const zstring const ptr ptr)
    if argc <= 1 then
        show_help = true
    end if
    for i as integer = 1 to argc - 1
        var arg = *argv[i]
        select case arg
        case "-v"
            show_debug = true
        case else
            clangargs.append(arg)
        end select
    next
end sub

private sub printHelp()
    print "fbbindgen 0.1"
    print "usage: fbbindgen foo.h [options] [clang options]"
    print "options:"
    print "  -v        Show debug output"
end sub

private function main(byval argc as integer, byval argv as const zstring const ptr ptr) as integer
    dim cmdline as CommandLineOptions
    cmdline.parse(argc, argv)

    if cmdline.show_help then
        printHelp()
        return 1
    end if

    dim logger as ErrorLogger
    if cmdline.show_debug then
        logger.eprint("libclang command line: " + cmdline.clangargs.dump())
    end if

    dim tu as ClangTU = ClangTU(cmdline.clangargs)
    tu.reportErrors(logger)

    if cmdline.show_debug then
        ClangAstDumper(@logger, @tu).dump()
    end if

    dim parser as TUParser = TUParser(@logger, @tu)
    parser.parse()

    if cmdline.show_debug then
        parser.ast->dump(logger)
    end if

    dim emit as Emitter
    emit.emitBinding(parser.ast)

    return iif(logger.haveErrors(), 1, 0)
end function

end main(__FB_ARGC__, __FB_ARGV__)
