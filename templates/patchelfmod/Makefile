BIN = patchelfmod

all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	g++ -w -s -I. -o $@ $@.cpp

