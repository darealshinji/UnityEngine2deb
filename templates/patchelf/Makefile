CXXFLAGS = -O3 -Wall -Wextra -Wcast-qual -I. -std=c++17 -D_FILE_OFFSET_BITS=64 -DPACKAGE_STRING='"PatchELF 0.18.0"'
LDFLAGS  = -s


all: patchelf

clean:
	-rm -f patchelf

distclean: clean

patchelf: patchelf.cpp
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

