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
	rm -rf $(MAKEFILE_DIR)/mix.lock
	rm -rf $(MAKEFILE_DIR)/_build/*
	rm -rf $(MAKEFILE_DIR)/deps/*

docs:
	rm -rf $(MAKEFILE_DIR)/doc/*
	mix docs

fetch:
	mix gs.fetch -u https://spreadsheets.google.com/feeds/worksheets/1k-N20RmT62RyocEu4-MIJm11DZqlZrzV89fGIddDzIs/public/basic -d priv/data

.PHONY: all deps compile run test docs clean fetch
