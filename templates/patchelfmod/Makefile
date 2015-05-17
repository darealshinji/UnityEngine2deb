BIN = patchelfmod

all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	g++ -s -I. -o $@ patchelfmod.cpp

