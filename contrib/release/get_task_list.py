#!/usr/bin/env python
import sys

assumeprovided = ["gcc-native-to-native"]
targets    =           ["lingnu32", "lingnu64", "linmus32", "linmus64", "win32", "win64", "dos"]
alltargets = ["native", "lingnu32", "lingnu64", "linmus32", "linmus64", "win32", "win64", "dos"]
linuxtargets = ["lingnu32", "lingnu64", "linmus32", "linmus64"]
builds = []

class Build:
    def __init__(self, name):
        self.name = name
        self.depends = []

def add(name):
    builds.append(Build(name))

def add_depends(dep):
    builds[-1].depends.append(dep)

def add_multitarget(name, depends=[], includetargets=alltargets, excludetargets=[], linux=0):
    if linux:
        includetargets = linuxtargets
    for target in includetargets:
        if not target in excludetargets:
            add(name + "-" + target)
            add_depends("gcc-native-to-" + target)
            for dep in depends:
                add_depends(dep + "-" + target)

add_multitarget("gmp")
add_multitarget("mpfr", depends=["gmp"])
add_multitarget("mpc", depends=["gmp", "mpfr"])
add_multitarget("libffi", excludetargets=["dos"])

add_multitarget("zlib")
add_multitarget("bzip2")
add_multitarget("libzip")
add_multitarget("lzo")
add_multitarget("xz")

add_multitarget("libpng")
add_multitarget("giflib")
add_multitarget("tiff")
add_multitarget("jpeglib")

add_multitarget("ncurses", linux=1)
add_multitarget("gpm"    , linux=1, depends=["ncurses"])

add_multitarget("freetype"  , excludetargets=["dos"], depends=["zlib", "bzip2", "libpng"])
add_multitarget("fontconfig", excludetargets=["dos"], depends=["zlib", "freetype"])

add_multitarget("util-macros" , linux=1)
add_multitarget("dri2proto"   , linux=1, depends=["util-macros"])
add_multitarget("dri3proto"   , linux=1, depends=["util-macros"])
add_multitarget("fixesproto"  , linux=1, depends=["util-macros"])
add_multitarget("glproto"     , linux=1, depends=["util-macros"])
add_multitarget("inputproto"  , linux=1, depends=["util-macros"])
add_multitarget("kbproto"     , linux=1, depends=["util-macros"])
add_multitarget("presentproto", linux=1, depends=["util-macros"])
add_multitarget("randrproto"  , linux=1, depends=["util-macros"])
add_multitarget("recordproto" , linux=1, depends=["util-macros"])
add_multitarget("renderproto" , linux=1, depends=["util-macros"])
add_multitarget("videoproto"  , linux=1, depends=["util-macros"])
add_multitarget("xcb-proto"   , linux=1, depends=["util-macros"])
add_multitarget("xextproto"   , linux=1, depends=["util-macros"])
add_multitarget("xf86dgaproto", linux=1, depends=["util-macros"])
add_multitarget("xf86vidmodeproto", linux=1, depends=["util-macros"])
add_multitarget("xineramaproto", linux=1, depends=["util-macros"])
add_multitarget("xproto"      , linux=1, depends=["util-macros"])
add_multitarget("libpthread-stubs", linux=1)
add_multitarget("xtrans"      , linux=1, depends=["util-macros"])
add_multitarget("libdrm"      , linux=1)
add_multitarget("libICE"      , linux=1, depends=["util-macros", "xproto", "xtrans"])
add_multitarget("liblbxutil"  , linux=1)
add_multitarget("libpciaccess", linux=1, depends=["util-macros"])
add_multitarget("libSM"       , linux=1, depends=["util-macros", "libICE", "xproto", "xtrans"])
add_multitarget("libX11"      , linux=1, depends=["util-macros", "xproto", "xextproto", "xtrans", "libxcb", "kbproto", "inputproto"])
add_multitarget("libXau"      , linux=1, depends=["util-macros", "xproto"])
add_multitarget("libxcb"      , linux=1, depends=["xcb-proto", "xproto", "libXau", "libpthread-stubs", "libXdmcp"])
add_multitarget("libXcursor"  , linux=1, depends=["util-macros", "libXrender", "libXfixes"])
add_multitarget("libXdmcp"    , linux=1, depends=["util-macros", "xproto"])
add_multitarget("libXext"     , linux=1, depends=["util-macros", "xproto", "xextproto", "libX11"])
add_multitarget("libXfixes"   , linux=1, depends=["util-macros", "xproto", "xextproto", "fixesproto", "libX11"])
add_multitarget("libXft"      , linux=1, depends=["util-macros", "libX11", "libXrender", "freetype", "fontconfig"])
add_multitarget("libXi"       , linux=1, depends=["util-macros", "inputproto", "libXext", "libXfixes"])
add_multitarget("libXinerama" , linux=1, depends=["util-macros", "xineramaproto", "libXext"])
add_multitarget("libXmu"      , linux=1, depends=["util-macros", "libXt", "libXext"])
add_multitarget("libXpm"      , linux=1, depends=["util-macros", "libXext", "libSM", "libXt"])
add_multitarget("libXrandr"   , linux=1, depends=["util-macros", "randrproto", "libX11", "libXrender", "libXext"])
add_multitarget("libXrender"  , linux=1, depends=["util-macros", "renderproto", "xproto", "libX11"])
add_multitarget("libXt"       , linux=1, depends=["util-macros", "kbproto", "libxcb", "libSM", "libX11",  "libXdmcp"])
add_multitarget("libXtst"     , linux=1, depends=["util-macros", "recordproto", "inputproto", "libXext", "libXi"])
add_multitarget("libXv"       , linux=1, depends=["util-macros", "videoproto", "libXext"])
add_multitarget("libXxf86dga" , linux=1, depends=["util-macros", "xf86dgaproto", "libXext"])
add_multitarget("libXxf86vm"  , linux=1, depends=["util-macros", "xf86vidmodeproto", "libXext"])

add_multitarget("mesa", linux=1)

for target in targets:
    add("binutils-native-to-" + target)
    add("gcc-native-to-" + target)
    add_depends("binutils-native-to-" + target)
    add_depends("gmp-native")
    add_depends("mpfr-native")
    add_depends("mpc-native")

add("fbc-native")
add("binutils-win32-to-win32")
add("binutils-win64-to-win64")
add("gcc-win32-to-win32")
add("gcc-win64-to-win64")
add_multitarget("fbc")
add("fbc-win32-standalone")
add("fbc-win64-standalone")
add("fbc-dos-standalone")

################################################################################

class TaskCollector:
    def __init__(self):
        self.tasks = []
        self.recursionstack = []

    def find_build(self, name):
        for i in builds:
            if i.name == name:
                return i
        raise RuntimeError("unknown task '" + name + "', wanted by " + str(self.recursionstack))

    def collect_tasks(self, name):
        if name in self.recursionstack:
            raise RuntimeError("circular dependency: " + str(self.recursionstack))
        self.recursionstack.append(name)

        if not name in assumeprovided:
            b = self.find_build(name)
            for dep in b.depends:
                if not dep in self.tasks:
                    self.collect_tasks(dep)
            self.tasks.append(name)

        self.recursionstack.pop()

collector = TaskCollector()
if len(sys.argv) > 1:
    tasks = sys.argv[1:]
    #print("collecting tasks for " + str(tasks) + " out of " + str(len(builds)) + " tasks total")
    for task in tasks:
        collector.collect_tasks(task)
else:
    #print("collecting all " + str(len(builds)) + " tasks")
    for b in builds:
        collector.collect_tasks(b.name)

for t in collector.tasks:
    print(t)
