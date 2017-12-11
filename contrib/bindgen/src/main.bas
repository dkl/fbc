#include once "ClangContext.bi"
#include once "ClangParser.bi"

type CommandLineOptions
    clangargs as ClangArgs
    show_help as boolean
    declare sub parse(byval argc as integer, byval argv as const zstring const ptr ptr)
    declare operator let(byref as const CommandLineOptions) '' unimplemented
end type

sub CommandLineOptions.parse(byval argc as integer, byval argv as const zstring const ptr ptr)
    if argc <= 1 then
        show_help = true
    end if
    for i as integer = 1 to argc - 1
        clangargs.append(*argv[i])
    next
end sub

private sub printHelp()
    print "fbbindgen 0.1"
    print "usage: fbbindgen foo.h [options]"
    print "options:"
end sub

private function main(byval argc as integer, byval argv as const zstring const ptr ptr) as integer
    dim cmdline as CommandLineOptions
    cmdline.parse(argc, argv)

    if cmdline.show_help then
        printHelp()
        return 1
    end if

    dim logger as ErrorLogger
    logger.printError("libclang command line: " + cmdline.clangargs.dump())

    dim tu as ClangTU = ClangTU(cmdline.clangargs)
    tu.reportErrors(logger)

    ClangAstDumper(@tu).dump()

    dim parser as TUParser = TUParser(@tu)
    parser.parse()

    return 0
end function

end main(__FB_ARGC__, __FB_ARGV__)
