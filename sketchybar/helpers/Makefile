# Small native helpers the Lua items call. sketchybarrc runs `make` on start,
# so they rebuild by themselves whenever a source file changes.

BIN := bin

all: $(BIN)/wifi $(BIN)/brightness

$(BIN):
	mkdir -p $(BIN)

$(BIN)/wifi: wifi.swift | $(BIN)
	swiftc -O $< -o $@

$(BIN)/brightness: brightness.c | $(BIN)
	clang -O2 -Wall $< -o $@ -framework IOKit -framework CoreFoundation -framework ApplicationServices

clean:
	rm -rf $(BIN)

.PHONY: all clean
