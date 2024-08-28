MAIN_PACKAGE_PATH := ./
BINARY_NAME := speedtest

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

.PHONY: no-dirty
no-dirty:
	git diff --exit-code


# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## tidy: format code and tidy modfile
.PHONY: tidy
tidy:
	go fmt ./...
	go mod tidy -v

## audit: run quality control checks
.PHONY: audit
audit:
	go mod verify
	go vet ./...
	go run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
	go run golang.org/x/vuln/cmd/govulncheck@latest ./...
	go test -race -buildvcs -vet=off ./...


# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## test: run all tests
.PHONY: test
test:
	go test -v -race -buildvcs ./...

## test/cover: run all tests and display coverage
.PHONY: test/cover
test/cover:
	go test -v -race -buildvcs -coverprofile=/tmp/coverage.out ./...
	go tool cover -html=/tmp/coverage.out

## build: build the application
.PHONY: build
build:
	go build -o=/tmp/bin/${BINARY_NAME} ${MAIN_PACKAGE_PATH}

## run: run the  application
.PHONY: run
run: build
	/tmp/bin/${BINARY_NAME}


# ==================================================================================== #
# OPERATIONS
# ==================================================================================== #

## push: push changes to the remote Git repository
.PHONY: push
push: tidy audit no-dirty
	git push

## load: use launchd to run locally every 6 hours and at system startup
.PHONY: load
load: confirm tidy audit no-dirty
	GOOS=linux GOARCH=arm64 go build -ldflags='-s' -o=/tmp/bin/macos_arm64/${BINARY_NAME} ${MAIN_PACKAGE_PATH}
	cp -af /tmp/bin/linux_amd64/${BINARY_NAME} /Users/dennisgilli/.local/bin/
	cp -af etc/com.dgilli.speedtest.plist Users/dennisgilli/Library/LaunchAgents/com.dgilli.speedtest.plist
	launchctl load ~/Library/LaunchAgents/com.dgilli.speedtest.plist

## unload: stop automatic local execution
.PHONY: unload
unload:
	launchctl unload ~/Library/LaunchAgents/com.dgilli.speedtest.plist
