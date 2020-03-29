prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install -d ".build/release/mimiq" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mimiq"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
