prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

build_debug:
	swift build

install: build
	mkdir -p "$(bindir)"
	install ".build/release/mimiq" "$(bindir)"

install_debug: build_debug
	mkdir -p "$(bindir)"
	install ".build/debug/mimiq" "$(bindir)"

test:
	swift test

uninstall:
	rm -rf "$(bindir)/mimiq"

clean:
	rm -rf .build
	# clear all cache and logging
	rm -rf ~/.mimiq

.PHONY: build build_debug install install_debug uninstall clean
