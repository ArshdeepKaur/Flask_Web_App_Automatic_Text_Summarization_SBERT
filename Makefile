#!/usr/bin/python3
# Copyright 2023 Coros, Corp. All rights reserved.

VENV = nlp_sumamrizer_project

# We stabilize the version of pip we use so as to avoid unexpected
# behavior.
PIP_VERSION = 23.3.1
PIP = $(VENV)/bin/pip3

PYTHON3 = python3
VPIP = $(VENV)/bin/pip3
VPYTHON = $(VENV)/bin/python3
VRUFF = $(VENV)/bin/ruff
VFLAKE8 = $(VENV)/bin/flake8
VPYRIGHT = $(VENV)/bin/pyright
VVULTURE = $(VENV)/bin/vulture
VAUTOPEP8 = $(VENV)/bin/autopep8
VPYLINT = $(VENV)/bin/pylint
VMYPY = $(VENV)/bin/mypy

RUFF_FLAGS = --fix
FLAKE8_FLAGS = --ignore=W292,E501 ##W292: no newline at end of file, E501: line too long
PYRIGHT_FLAGS = --venvpath=$(dir $(VENV))
AUTOPEP8_FLAGS = -v --in-place --aggressive -a -a -a --max-line-length=80
MYPY_FLAGS = --ignore-missing-imports
PYLINT_FLAGS = --rcfile="pyproject.toml"

# Reliably detect when requirements.in changes
REQUIREMENTS = requirements.in
DEPS_HASH = $(firstword $(shell sha1sum $(REQUIREMENTS)))

VENV_INSTALLED = $(VENV)/deps.hash.$(DEPS_HASH)

SRCS = app.py
CHECK_SRCS = $(SRCS) ../utility/utils.py ../utility/__init__.py

PYTHONPATH:= $(PYTHONPATH):$(abspath ../):$(abspath ../utility):../:./
$(info $$PYTHONPATH is [${PYTHONPATH}])
export PYTHONPATH

run: $(VENV_INSTALLED)
	$(VPYTHON) $(SRCS) $(ARGS)

.PHONY: venv
venv: $(VENV_INSTALLED)

$(VENV_INSTALLED):
	rm -fr $(VENV)
	rm -fr requirements.txt
	$(PYTHON3) -m venv $(VENV)
	$(VPIP) install --upgrade pip==$(PIP_VERSION)
	$(VPIP) install pip-tools
	$(VENV)/bin/pip-compile --resolver=backtracking -o requirements.txt $(REQUIREMENTS)
	$(VPIP) install -r requirements.txt
	touch $(VENV_INSTALLED)

.PHONY: ruff
ruff: $(VENV_INSTALLED)
	@echo "--- ruff ---"
	-$(VRUFF) $(RUFF_FLAGS) $(CHECK_SRCS)

.PHONY: pylint
pylint: $(VENV_INSTALLED)
	@echo "--- pylint ---"
	-$(VPYLINT) $(PYLINT_FLAGS) $(CHECK_SRCS)

.PHONY: flake8
flake8: $(VENV_INSTALLED)
	@echo "--- flake8 ---"
	-$(VFLAKE8) $(FLAKE8_FLAGS) $(CHECK_SRCS)

.PHONY: pyright
pyright: $(VENV_INSTALLED)
	@echo "--- pyright ---"
	-$(VPYRIGHT) $(PYRIGHT_FLAGS) $(CHECK_SRCS)

.PHONY: autopep8
autopep8: $(VENV_INSTALLED)
	@echo "--- autopep8 ---"
	-$(VAUTOPEP8) $(AUTOPEP8_FLAGS) $(CHECK_SRCS)

.PHONY: mypy
mypy: $(VENV_INSTALLED)
	@echo "--- mypy ---"
	-$(VMYPY) $(MYPY_FLAGS) $(CHECK_SRCS)

.PHONY: check
check: ruff pylint flake8 mypy pyright

clean:
	rm -rf __pycache__
	rm -rf $(VENV)