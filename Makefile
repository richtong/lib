# Makefile for richtong/lib
#
# Release tag
TAG=0.9

# adjust this for where ./src/lib is
LIB_DIR=.


## Local directory Make commands
## ----------
## test: test the library
.PHONY: test
test:
	@echo "insert test code here..."

## clean: remove the build directory
.PHONY: clean
clean:
	@echo "insert clear code here..."

## all: build all
.PHONY: all

# list these in reverse order so the most general is last
include $(LIB_DIR)/include.python.mk

# pipenv is deprecated
# include $(LIB_DIR)/include.pipenv.mk

# rhash is optional for hash checks
# include $(LIB_DIR)/include.rhash.mk

# include $(LIB_DIR)/include.pipenv.mk
include $(LIB_DIR)/include.mk
