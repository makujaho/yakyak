.DEFAULT_GOAL := all

UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin SunOS FreeBSD GNU/kFreeBSD NetBSD OpenBSD))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS := darwin
BUILD := darwin win32 linux
else
ifeq ($(UNAME),$(filter $(UNAME),SunOS))
OS := solaris
else
ifeq ($(UNAME),$(filter $(UNAME),FreeBSD GNU/kFreeBSD NetBSD OpenBSD))
OS := bsd
else
OS := linux
BUILD := win32 linux
endif
endif
endif
else
OS := windows
BUILD := win32
endif

CURL := $(shell which curl 2>/dev/null)
UNZIP := $(shell which unzip 2>/dev/null)
SED := $(shell which sed 2>/dev/null)
NPM := $(shell which npm 2>/dev/null)

ELECTRON_VERSION := $(shell npm info electron-prebuilt version 2>/dev/null)
YAKYAK_VERSION=$(shell node -e 'console.log(require(\'./package\').version)')

PLATFORMS := "darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64"

NO_COLOR=\033[0m
OK_COLOR=\033[48;5;0;38;5;46m
NOTICE_COLOR=\033[48;5;0;38;5;46m
ERROR_COLOR=\033[48;5;255;38;5;196m
WARN_COLOR=\033[48;5;0;38;5;202m

OK_STRING=$(OK_COLOR)[OK]$(NO_COLOR)      
NOTICE_STRING=$(NOTICE_COLOR)[NOTICE]$(NO_COLOR)  
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)   
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR) 

PRINT_ERROR = @printf "$(ERROR_STRING) $1\n" && false
PRINT_WARNING = @printf "$(WARN_STRING) $1\n"
PRINT_WARNING_SH = printf "$(WARN_STRING) $1\n"
PRINT_OK = @printf "$(OK_STRING) $1\n"
PRINT_NOTICE = @printf "$(NOTICE_STRING) $1\n"

define DL_ELECTRON
	$(call PRINT_NOTICE,'v$2 electron for $1')

	@if ! [[ "$(BUILD)" = *$(subst -ia32,,$(subst -x64,,$1))* ]]; then \
		$(call PRINT_WARNING_SH,'Building electron for $1 on this platform is not supported'); \
		exit; \
	fi

	$(shell mkdir -p dist)

	@test -f dist/electron-v$2-$1.zip || \
		curl -o dist/electron-v$2-$1.zip \
		-LO https://github.com/atom/electron/releases/download/v$2/electron-v$2-$1.zip 2>/dev/null

	$(call PRINT_NOTICE,'Unpacking v$2 electron for $1')
	@test -f dist/$1 || \
		unzip -o dist/electron-v$2-$1.zip -d dist/$1 1>/dev/null

	$(call PRINT_OK,'v$2 electron for $1 downloaded')
endef

.PHONY: all
all: check clean deploy

.PHONY: reload
reload: mostlyclean npm_install app deploy

.PHONY: npm_install
npm_install: check-npm
	$(call PRINT_NOTICE,'Running npm install')
	@npm install; if [ $$? -ne 0 ]; then \
		$(call PRINT_ERROR,'npm install exited with error(s)'); \
	fi
	$(call PRINT_OK,'npm install successfull')

.PHONY: app
app: npm_install
	$(call PRINT_NOTICE,'Running gulp')
	@gulp; if [ $$? -ne 0 ]; then \
		$(call PRINT_ERROR,'gulp exited with error(s)'); \
	fi
	$(call PRINT_OK,'gulp executed successfully')

.PHONY: deploy
deploy: check app deploy-electron deploy-darwin-x64 deploy-win32-ia32 \
	deploy-win32-x64 deploy-linux-ia32 deploy-linux-x64

.PHONY: deploy-electron
deploy-electron:
	$(foreach PLATFORM,$(PLATFORMS), $(call DL_ELECTRON,$(PLATFORM),$(ELECTRON_VERSION)))

.PHONY: deploy-darwin-x64
deploy-darwin-x64: deploy-electron check app
ifneq ($(filter $(BUILD),darwin),)
	$(call PRINT_NOTICE,Building for darwin)
	@cd dist/darwin-x64/ && {\
		mv Electron.app Yakyak.app; \
		defaults write $$(pwd)/Yakyak.app/Contents/Info.plist CFBundleDisplayName -string "Yakyak"; \
		defaults write $$(pwd)/Yakyak.app/Contents/Info.plist CFBundleExecutable -string "Yakyak"; \
		defaults write $$(pwd)/Yakyak.app/Contents/Info.plist CFBundleIdentifier -string "com.github.yakyak"; \
		defaults write $$(pwd)/Yakyak.app/Contents/Info.plist CFBundleName -string "Yakyak"; \
		defaults write $$(pwd)/Yakyak.app/Contents/Info.plist CFBundleVersion -string "$VERSION"; \
		plutil -convert xml1 $$(pwd)/Yakyak.app/Contents/Info.plist; \
		mv Yakyak.app/Contents/MacOS/Electron Yakyak.app/Contents/MacOS/Yakyak; \
		cp -R ../../app Yakyak.app/Contents/Resources/app; \
		cp ../../src/icons/atom.icns Yakyak.app/Contents/Resources/atom.icns; \
		zip -r ../yakyak-osx.app.zip Yakyak.app; \
	}
else
	$(call PRINT_WARNING,Not building for darwin/OS/OSX)
endif

.PHONY: deploy-win32-ia32
deploy-win32-ia32: deploy-electron check app
ifneq ($(filter $(BUILD),windows),)
	$(call PRINT_NOTICE,Building for win32-ia32)
	@cd dist/ && { \
		mv win32-ia32/electron.exe win32-ia32/yakyak.exe; \
		cp -R ../app win32-ia32/resources/app; \
		zip -r yayak-win32-ia32.zip win32-ia32; \
	}
else
	$(call PRINT_WARNING,Not building for win32-ia32)
endif

.PHONY: deploy-win32-x64
deploy-win32-x64: deploy-electron check app
ifneq ($(filter $(BUILD),windows),)
	$(call PRINT_NOTICE,Building for win32-x64)
	@cd dist/ && { \
		mv win32-x64/electron.exe win32-x64/yakyak.exe; \
		cp -R ../app win32-x64/resources/app; \
		zip -r yayak-win32-x64.zip win32-x64; \
	}
else
	$(call PRINT_WARNING,Not building for win32-x64)
endif

.PHONY: deploy-linux-ia32
deploy-linux-ia32: deploy-electron check app
ifneq ($(filter $(BUILD),linux),)
	$(call PRINT_NOTICE,Building for linux-ia32)
	@cd dist/ && { \
		mv linux-ia32/electron linux-ia32/yakyak; \
		cp -R ../app linux-ia32/resources/app; \
		zip -r yayak-linux-ia32.zip linux-ia32; \
	}
else
	$(call PRINT_WARNING,Not building for linux-ia32)
endif

.PHONY: deploy-linux-x64
deploy-linux-x64: deploy-electron check app
ifneq ($(filter $(BUILD),linux),)
	$(call PRINT_NOTICE,Building for linux-x64)
	@cd dist/ && { \
		mv linux-x64/electron linux-x64/yakyak; \
		cp -R ../app linux-x64/resources/app; \
		zip -r yayak-linux-x64.zip linux-x64; \
	}
else
	$(call PRINT_WARNING,Not building for linux-x64)
endif

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
