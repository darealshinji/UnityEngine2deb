CXX := g++
BIN  = patchelf

PAGESIZE = $(shell getconf PAGESIZE 2>/dev/null || getconf PAGE_SIZE 2>/dev/null || echo 4096)
DEFINES  = -DPACKAGE_STRING="\"PatchELF 0.10\"" -DPAGESIZE=$(PAGESIZE)


all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	$(CXX) -std=c++11 -w -s $(DEFINES) -o $@ $@.cpp

