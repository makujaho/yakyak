.DEFAULT_GOAL := all

UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin SunOS FreeBSD GNU/kFreeBSD NetBSD OpenBSD))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS := darwin
BUILD := darwin windows linux
else
ifeq ($(UNAME),$(filter $(UNAME),SunOS))
OS := solaris
else
ifeq ($(UNAME),$(filter $(UNAME),FreeBSD GNU/kFreeBSD NetBSD OpenBSD))
OS := bsd
else
OS := linux
BUILD := windows linux
endif
endif
endif
else
OS := windows
BUILD := windows
endif

CURL := $(shell which curl 2>/dev/null)
UNZIP := $(shell which unzip 2>/dev/null)
SED := $(shell which sed 2>/dev/null)
NPM := $(shell which npm 2>/dev/null)

ELECTRON_VERSION := $(shell npm info electron-prebuilt version 2>/dev/null)

PLATFORMS := "darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64"

NO_COLOR=\033[0m
OK_COLOR=\033[48;5;0;38;5;46m
ERROR_COLOR=\033[48;5;255;38;5;196m
WARN_COLOR=\033[48;5;0;38;5;202m

OK_STRING=$(OK_COLOR)[OK]$(NO_COLOR)      
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)   
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR) 

PRINT_ERROR = @printf "$(ERROR_STRING) $1\n" && false
PRINT_WARNING = @printf "$(WARN_STRING) $1\n"
PRINT_OK = @printf "$(OK_STRING) $1\n"

define DL_ELECTRON
	$(shell mkdir -p dist)
	@echo 'Downloading v$2 electron for $1'
	@test -f dist/electron-v$2-$1.zip || \
		curl -o dist/electron-v$2-$1.zip \
		-LO https://github.com/atom/electron/releases/download/v$2/electron-v$2-$1.zip
	@echo 'Unpacking v$2 electron for $1'
	@test -f dist/$1 || \
		unzip -o dist/electron-v$2-$1.zip -d dist/$1 1>/dev/null
endef

.PHONY: all
all: clean npm_install app deploy reload mostlyclean

.PHONY: reload
reload: mostlyclean npm_install app deploy

.PHONY: npm_install
npm_install: check-npm
	@echo 'Running npm install'
	@npm install; if [ $$? -ne 0 ]; then \
		$(call PRINT_ERROR 'npm install exited with error(s)'); \
	fi
	$(call PRINT_OK 'npm install successfull')

.PHONY: app
app: npm_install
	gulp

.PHONY: deploy
deploy: check app
	$(foreach PLATFORM,$(PLATFORMS),$(call DL_ELECTRON,$(PLATFORM),$(ELECTRON_VERSION)))
	./deploy.sh

.PHONY: mostlyclean
mostlyclean:
	rm -rf app/
	rm -rf dist/*/*

.PHONY: clean
clean:
	rm -rf app/
	rm -rf dist/

.PHONY: check
check: check-os check-curl check-unzip check-sed check-npm

.PHONY: check-os
check-os:
ifeq ($(OS),solaris)
	$(call PRINT_ERROR,Solaris not supported)
endif

ifeq ($(OS),bsd)
	$(call PRINT_ERROR,BSD not supported)
endif

ifeq ($(OS),linux)
	$(call PRINT_OK,Current OS is Linux)
	$(call PRINT_WARNING,Won\'t be able to build for Darwin/OSX)
endif

ifeq ($(OS),darwin)
	$(call PRINT_OK,Current OS is Darwin/OSX)
endif

ifeq ($(OS),windows)
	$(call PRINT_OK,Current OS is Windows)
	$(call PRINT_WARNING,Building on Windows is untested)
endif

.PHONY: check-curl
check-curl:
ifneq (,$(CURL))
	$(call PRINT_OK,curl found in $(CURL))
else
	$(call PRINT_ERROR,curl not found)
endif

.PHONY: check-unzip
check-unzip:
ifneq (,$(UNZIP))
	$(call PRINT_OK,unzip found in $(UNZIP))
else
	$(call PRINT_ERROR,unzip not found)
endif

.PHONY: check-sed
check-sed:
ifneq (,$(SED))
	$(call PRINT_OK,sed found in $(SED))
else
	$(call PRINT_ERROR,sed not found)
endif

.PHONY: check-npm
check-npm:
ifneq (,$(NPM))
	$(call PRINT_OK,npm found in $(NPM))
else
	$(call PRINT_ERROR,npm not found)
endif
