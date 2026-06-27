VERSION != grep '^version:' cli/src/bashly.yml | awk '{print $$2}'
PREFIX ?= /usr/local
DESTDIR ?=
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
SYSCONFDIR ?= /etc/xdg
LOCALSTATEDIR ?= /var/lib
STATEDIR ?= $(LOCALSTATEDIR)
ICON_PATH ?= $(DATADIR)/icons/hicolor/scalable/apps/msnap.svg

# Installation Directories
APP_DIR = $(DESTDIR)$(DATADIR)/msnap
GUI_DIR = $(APP_DIR)/gui
ICON_DIR = $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps
DESKTOP_DIR = $(DESTDIR)$(DATADIR)/applications
CONFIG_DIR = $(DESTDIR)$(SYSCONFDIR)/msnap

# Manifest
MANIFEST = $(DESTDIR)$(STATEDIR)/msnap/.manifest

.PHONY: all build install uninstall clean version

all: build

build:
	@echo "Generating files..."
	sed "s|@GUI_PATH@|$(DATADIR)/msnap/gui|g" assets/msnap.desktop.in | \
		sed "s|@ICON_PATH@|$(ICON_PATH)|g" > msnap.desktop
	sed "s|@BIN_PATH@|$(BINDIR)/msnap|g" gui/Config.qml > Config.qml.build
	sed \
		-e "s|@GUI_PATH@|$(DATADIR)/msnap/gui|g" \
		-e "s|@VERSION@|$(VERSION)|g" \
		-e "s|@MANIFEST_PATH@|$(MANIFEST)|g" \
		cli/msnap > msnap.build

install: build
	@echo "Installing msnap..."
	
	# Install CLI binary
	install -d $(DESTDIR)$(BINDIR)
	install -m755 msnap.build $(DESTDIR)$(BINDIR)/msnap
	
	# Install Config files
	install -d $(CONFIG_DIR)
	install -m644 cli/msnap.conf $(CONFIG_DIR)/msnap.conf
	install -m644 gui/gui.conf $(CONFIG_DIR)/gui.conf
	
	# Install GUI Application Files
	install -d $(GUI_DIR)/icons
	install -d $(GUI_DIR)/components
	install -d $(GUI_DIR)/services
	install -m644 gui/*.qml $(GUI_DIR)/
	install -m644 gui/components/*.qml $(GUI_DIR)/components/
	install -m644 gui/services/*.qml $(GUI_DIR)/services/
	install -m644 Config.qml.build $(GUI_DIR)/Config.qml
	install -m644 gui/icons/*.svg $(GUI_DIR)/icons/
	
	# Install Desktop entry and Icon
	install -d $(DESKTOP_DIR)
	install -d $(ICON_DIR)
	install -m644 msnap.desktop $(DESKTOP_DIR)/msnap.desktop
	install -m644 assets/icons/msnap.svg $(ICON_DIR)/msnap.svg

	# Write manifest
	@install -d $(DESTDIR)$(STATEDIR)/msnap
	@{ \
		echo "$(DESTDIR)$(BINDIR)/msnap"; \
		find $(GUI_DIR) -type f | sort; \
		echo "$(CONFIG_DIR)/msnap.conf"; \
		echo "$(CONFIG_DIR)/gui.conf"; \
		echo "$(DESKTOP_DIR)/msnap.desktop"; \
		echo "$(ICON_DIR)/msnap.svg"; \
	} > $(MANIFEST)
	@echo "Manifest written to $(MANIFEST)"

uninstall:
	@if [ ! -f "$(MANIFEST)" ]; then \
		echo "Error: manifest not found at $(MANIFEST) — was msnap installed?"; \
		exit 1; \
	fi
	@echo "Uninstalling msnap (using manifest)..."
	@xargs rm -f < $(MANIFEST)
	@sed 's|/[^/]*$$||' $(MANIFEST) | sort -ru | \
		xargs -I{} rmdir --ignore-fail-on-non-empty {} 2>/dev/null || true
	@rm -f $(MANIFEST)
	@rmdir --ignore-fail-on-non-empty $(DESTDIR)$(STATEDIR)/msnap 2>/dev/null || true
	@echo "Done."

clean:
	rm -f msnap.desktop Config.qml.build msnap.build

version:
	@echo "$(VERSION)" > VERSION
	@echo "VERSION set to $(VERSION)"
