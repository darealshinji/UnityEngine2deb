BIN = patchelfmod

all: $(BIN)

clean:
	rm -f $(BIN)

distclean: clean

$(BIN):
	g++ -W -s -I. -o $@ $@.cpp

