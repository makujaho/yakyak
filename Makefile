.DEFAULT_GOAL := all

CURL := $(shell which curl)
UNZIP := $(shell which unzip)
SED := $(shell which sed)

PLATFORMS := ("darwin-x64" "linux-ia32" "linux-x64" "win32-ia32" "win32-x64")

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m

OK_STRING=$(OK_COLOR)[OK]$(NO_COLOR)      
ERROR_STRING=$(ERROR_COLOR)[ERROR]$(NO_COLOR)  
WARN_STRING=$(WARN_COLOR)[WARNING]$(NO_COLOR) 

PRINT_ERROR = @printf "$(ERROR_STRING) $1\n" && false
PRINT_WARNING = @printf "$(WARN_STRING) $1\n"
PRINT_OK = @printf "$(OK_STRING) $1\n"

.PHONY: all
all: clean npm_install app deploy reload mostlyclean

.PHONY: reload
reload: mostlyclean npm_install app deploy

.PHONY: npm_install
npm_install:
	npm install

.PHONY: app
app:
	gulp

.PHONY: deploy
deploy: check
	for PLATFORM in $(PLATFORMS)
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
check: check-curl check-unzip check-sed

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
