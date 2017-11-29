FBC := fbc
prefix := /usr/local
LLVM_LIBDIR := $(shell llvm-config-4.0 --libdir)
FBBINDGEN := $(shell $(FBC) -m fbbindgen -print x)

-include config.mk

ALLFBCFLAGS := -m main -maxerr 1 $(FBFLAGS)
ALLFBLFLAGS := $(FBFLAGS)
LIBS := -p $(LLVM_LIBDIR) -l clang

SOURCES := $(sort $(wildcard src/*.bas))
HEADERS := $(wildcard src/*.bi)
OBJECTS := $(patsubst src/%.bas,src/obj/%.o,$(SOURCES))

# We don't want to use any of make's built-in suffixes/rules
.SUFFIXES:

ifndef V
  QUIET_FBC     = @echo "FBC $<";
  QUIET_FBCLINK = @echo "FBCLINK $@";
endif

compile: $(FBBINDGEN)

$(FBBINDGEN): $(OBJECTS)
	$(QUIET_FBCLINK)$(FBC) $(ALLFBLFLAGS) $^ $(LIBS) -x $@

$(OBJECTS): src/obj/%.o: src/%.bas $(HEADERS)
	$(QUIET_FBC)$(FBC) $(ALLFBCFLAGS) $< -c -o $@

clean:
	rm -f $(FBBINDGEN) src/obj/*.o

install:
	install $(FBBINDGEN) "$(prefix)/bin"

.PHONY: compile clean install
