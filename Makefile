SWIFT ?= swift
APP_NAME := MiniBar
CONFIGURATION ?= release
BIN_DIR := $(shell $(SWIFT) build -c $(CONFIGURATION) --show-bin-path)
BIN := $(BIN_DIR)/$(APP_NAME)
APP_BUNDLE := .build/$(APP_NAME).app
CONTENTS := $(APP_BUNDLE)/Contents

.PHONY: test build app run release clean

test:
	$(SWIFT) test

build:
	$(SWIFT) build -c $(CONFIGURATION)

app: build
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(CONTENTS)/MacOS" "$(CONTENTS)/Resources"
	cp "$(BIN)" "$(CONTENTS)/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	cp Resources/AppIcon.icns "$(CONTENTS)/Resources/AppIcon.icns"
	codesign --force --deep --sign - "$(APP_BUNDLE)"

run: app
	open "$(APP_BUNDLE)"

release: app

clean:
	rm -rf .build
