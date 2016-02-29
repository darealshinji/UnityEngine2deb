CXX := g++
BIN  = patchelf

PAGESIZE = $(shell getconf PAGESIZE 2>/dev/null || getconf PAGE_SIZE 2>/dev/null || echo 4096)
DEFINES  = -DPACKAGE_STRING="\"PatchELF 0.9\"" -DPAGESIZE=$(PAGESIZE)


all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	$(CXX) -w -s $(DEFINES) -o $@ $@.cpp

