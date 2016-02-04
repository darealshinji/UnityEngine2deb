CXX := g++
BIN = patchelf

all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	$(CXX) -w -s -DPACKAGE_STRING="\"PatchELF 0.8\"" -DHAVE_SYSCONF=1 -DHAVE_ELF_H=1 -o $@ $@.cpp

