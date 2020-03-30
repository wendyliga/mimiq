prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release

install: build
	mkdir -p "$(bindir)"
	install ".build/release/mimiq" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mimiq"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
