prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	mkdir -p "$(bindir)"
	install ".build/release/mimiq" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mimiq"

clean:
	rm -rf .build
	# clear all cache and logging
	rm -rf ~/.mimiq

.PHONY: build install uninstall clean
