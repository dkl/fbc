private sub printHelpAndExit()
	print "fbbindgen 0.1 (built on " + __DATE_ISO__ + ")"
	print "usage: fbbindgen foo.h [options]"
	print "options:"
	end 1
end sub

if  __FB_ARGC__ <= 1 then
    printHelpAndExit()
end if
