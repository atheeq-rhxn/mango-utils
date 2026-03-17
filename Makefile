PREFIX ?= /usr/local
DESTDIR ?=
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
SYSCONFDIR ?= /etc/xdg
ICON_PATH ?= $(DATADIR)/icons/hicolor/scalable/apps/msnap.svg

# Installation Directories
APP_DIR = $(DESTDIR)$(DATADIR)/msnap
GUI_DIR = $(APP_DIR)/gui
ICON_DIR = $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps
DESKTOP_DIR = $(DESTDIR)$(DATADIR)/applications
CONFIG_DIR = $(DESTDIR)$(SYSCONFDIR)/msnap

.PHONY: all install uninstall clean

all: build

build:
	@echo "Generating files..."
	sed "s|@GUI_PATH@|$(DATADIR)/msnap/gui|g" assets/msnap.desktop.in | \
		sed "s|@ICON_PATH@|$(ICON_PATH)|g" > msnap.desktop
	sed "s|@BIN_PATH@|$(BINDIR)/msnap|g" gui/Config.qml > Config.qml.build
	sed "s|@GUI_PATH@|$(DATADIR)/msnap/gui|g" cli/msnap > msnap.build

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
	install -m644 gui/*.qml $(GUI_DIR)/
	install -m644 Config.qml.build $(GUI_DIR)/Config.qml
	install -m644 gui/icons/*.svg $(GUI_DIR)/icons/
	
	# Install Desktop entry and Icon
	install -d $(DESKTOP_DIR)
	install -d $(ICON_DIR)
	install -m644 msnap.desktop $(DESKTOP_DIR)/msnap.desktop
	install -m644 assets/icons/msnap.svg $(ICON_DIR)/msnap.svg

uninstall:
	@echo "Uninstalling msnap..."
	rm -f $(DESTDIR)$(BINDIR)/msnap
	rm -rf $(CONFIG_DIR)/msnap.conf
	rm -rf $(CONFIG_DIR)/gui.conf
	rm -rf $(APP_DIR)
	rm -f $(DESKTOP_DIR)/msnap.desktop
	rm -f $(ICON_DIR)/msnap.svg

clean:
	rm -f msnap.desktop Config.qml.build msnap.build
