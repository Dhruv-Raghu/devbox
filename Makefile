.DEFAULT_GOAL := help

.PHONY: help create provision verify shell destroy

help:
	@printf '%s\n' 'Usage: make <create|provision|verify|shell|destroy> INSTANCE=<name>'

create provision verify shell destroy:
	@test -n "$(INSTANCE)" || { printf '%s\n' 'INSTANCE is required' >&2; exit 2; }
	@./scripts/$@ "$(INSTANCE)"
