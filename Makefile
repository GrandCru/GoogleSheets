MAKEFILE_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all: run

deps:
	mix deps.get
	mix deps.compile

compile: deps
	mix compile

run: compile
	iex -S mix run

test: compile
	mix test

clean:
	mix clean --all
	mix deps.clean --all

.PHONY: all deps compile run test clean
