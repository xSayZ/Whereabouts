# make test      lint + the offline test suite
# make package   test, then build dist/Whereabouts-<version>.zip (what players get) and check its layout
# make source    test, then build dist/Whereabouts-<version>-source.zip (adds tests, docs, CI config)
# make tag       test, check the tree is clean, create the annotated release tag v<version> (does not push)
ADDON   := Whereabouts
VERSION := $(shell sed -n 's/^## Version: *//p' $(ADDON).toc | tr -d '\r')
RUNTIME := $(ADDON).toc Bindings.xml $(wildcard *.lua) README.md CHANGELOG.md $(wildcard LICENSE*)
SOURCE  := $(RUNTIME) Makefile CLAUDE.md CONTRIBUTING.md SECURITY.md .pkgmeta .luacheckrc .gitignore .gitattributes .github docs scripts tests

.PHONY: test lint package source tag clean

lint:
	@for f in *.lua tests/*.lua; do luac5.1 -p $$f || exit 1; done; echo "syntax ok"
	@if command -v luacheck >/dev/null 2>&1; then luacheck . --no-color -q || exit 1; else echo "luacheck not installed: skipped (CI runs it)"; fi

test: lint
	@lua5.1 tests/run.lua

package: test
	@rm -rf dist/stage && mkdir -p dist/stage/$(ADDON)
	@cp $(RUNTIME) dist/stage/$(ADDON)/
	@cd dist/stage && zip -qr ../$(ADDON)-$(VERSION).zip $(ADDON)
	@rm -rf dist/stage
	@bash scripts/check-zip.sh dist/$(ADDON)-$(VERSION).zip
	@echo "built dist/$(ADDON)-$(VERSION).zip"

source: test
	@rm -rf dist/stage && mkdir -p dist/stage/$(ADDON)
	@cp -r $(SOURCE) dist/stage/$(ADDON)/
	@cd dist/stage && zip -qr ../$(ADDON)-$(VERSION)-source.zip $(ADDON)
	@rm -rf dist/stage
	@echo "built dist/$(ADDON)-$(VERSION)-source.zip"

tag: test
	@git diff --quiet && git diff --cached --quiet || { echo "working tree has uncommitted changes"; exit 1; }
	@bash scripts/check-tag.sh v$(VERSION) >/dev/null
	@git tag -a v$(VERSION) -m "$(ADDON) $(VERSION)"
	@echo "created tag v$(VERSION). Push it to release: git push origin main v$(VERSION)"

clean:
	@rm -rf dist
