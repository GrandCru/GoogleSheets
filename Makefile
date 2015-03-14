MAKEFILE_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all: run

deps:
	mix deps.get
	mix deps.compile

compile:
	mix compile

run:
	iex -S mix run

test:
	mix test

clean:
	mix clean --all
	mix deps.clean --all

fetch:
	mix gs.fetch -s https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -d priv/data

.PHONY: all deps compile run test clean
