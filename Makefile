.DEFAULT_GOAL := help

.PHONY: help create provision verify shell destroy

help:
	@printf '%s\n' 'Devbox controller scaffold (no lifecycle actions are enabled yet).'
	@printf '%s\n' 'See docs/DEVBOX_CONTROLLER_PLAN.md before implementing targets.'

create provision verify shell destroy:
	@printf '%s\n' 'This lifecycle target is intentionally disabled during scaffold phase.' >&2
	@exit 2
