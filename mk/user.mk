.PHONY: help doctor create check trace wave clean verilator-version create-design \
	user-lint user-test user-frame-test user-check lint-user \
	design-lint design-test design-frame-test design-wave

help:
	@printf '%s\n' 'mpc-frame user commands'
	@printf '%s\n' '  make doctor                         Check required tools'
	@printf '%s\n' '  make create NAME=counter32          Create a design package'
	@printf '%s\n' '              [TOP_NAME=CounterTop]   Override the RTL top module name'
	@printf '%s\n' '  make check [DESIGN=designs/name]    Run lint, unit, and Frame tests'
	@printf '%s\n' '  make trace [DESIGN=designs/name]    Run the Frame test with FST tracing'
	@printf '%s\n' '  make wave [DESIGN=designs/name]     Open the generated FST in GTKWave'
	@printf '%s\n' '  make clean                          Remove generated build output'

doctor:
	@command -v $(PYTHON) >/dev/null || (printf '%s\n' 'ERROR: Python 3 not found'; exit 127)
	@command -v $(CXX) >/dev/null || (printf '%s\n' 'ERROR: C++ compiler not found'; exit 127)
	@command -v $(VERILATOR) >/dev/null || (printf '%s\n' 'ERROR: Verilator not found'; exit 127)
	@actual=$$($(VERILATOR) --version | awk '{print $$2}'); \
	printf 'Python: %s\n' "$$($(PYTHON) --version 2>&1)"; \
	printf 'C++: %s\n' "$$($(CXX) --version | head -n 1)"; \
	printf 'Verilator: %s (required: %s)\n' "$$actual" '$(VERILATOR_RECOMMENDED_VERSION)'; \
	test "$$actual" = '$(VERILATOR_RECOMMENDED_VERSION)' || (printf '%s\n' \
		'ERROR: unsupported Verilator version'; exit 2)

verilator-version:
	@$(VERILATOR) --version
	@printf '%s\n' 'Required Verilator version: $(VERILATOR_RECOMMENDED_VERSION)'

create:
	@test -n "$(NAME)" || (printf '%s\n' \
		'ERROR: NAME is required, for example NAME=counter32'; exit 2)
	@$(PYTHON) $(REGISTRY_TOOL) create-design --name $(NAME) \
		--template $(DESIGN_TEMPLATE) --output $(DESIGN_OUTPUT) \
		--registry $(REGISTRY_MANIFEST) $(CREATE_TOP_ARG)

check:
	@$(MAKE) -f $(FRAME_MAKEFILE) user-check DESIGN="$(DESIGN)" TRACE=$(TRACE)

trace:
	@$(MAKE) -f $(FRAME_MAKEFILE) user-frame-test DESIGN="$(DESIGN)" TRACE=1 $(if $(TEST),TEST=$(TEST),)

wave:
	@design=$$($(PYTHON) $(REGISTRY_TOOL) find-user-design \
		--designs-root $(FRAME_ROOT)/designs --registry $(REGISTRY_MANIFEST) \
		$(USER_DESIGN_ARG)) || exit $$?; \
	$(MAKE) -f $(FRAME_MAKEFILE) design-wave DESIGN="$$design" $(if $(TEST),TEST=$(TEST),)

user-lint:
	@design=$$($(PYTHON) $(REGISTRY_TOOL) find-user-design \
		--designs-root $(FRAME_ROOT)/designs --registry $(REGISTRY_MANIFEST) \
		$(USER_DESIGN_ARG)) || exit $$?; \
	$(MAKE) -f $(FRAME_MAKEFILE) design-lint DESIGN="$$design"

user-test:
	@design=$$($(PYTHON) $(REGISTRY_TOOL) find-user-design \
		--designs-root $(FRAME_ROOT)/designs --registry $(REGISTRY_MANIFEST) \
		$(USER_DESIGN_ARG)) || exit $$?; \
	$(MAKE) -f $(FRAME_MAKEFILE) design-test DESIGN="$$design" $(if $(TEST),TEST=$(TEST),)

user-frame-test:
	@design=$$($(PYTHON) $(REGISTRY_TOOL) find-user-design \
		--designs-root $(FRAME_ROOT)/designs --registry $(REGISTRY_MANIFEST) \
		$(USER_DESIGN_ARG)) || exit $$?; \
	$(MAKE) -f $(FRAME_MAKEFILE) design-frame-test DESIGN="$$design" \
		$(if $(TEST),TEST=$(TEST),) TRACE=$(TRACE)

user-check:
	@$(MAKE) -f $(FRAME_MAKEFILE) user-lint DESIGN="$(DESIGN)"
	@$(MAKE) -f $(FRAME_MAKEFILE) user-test DESIGN="$(DESIGN)"
	@$(MAKE) -f $(FRAME_MAKEFILE) user-frame-test DESIGN="$(DESIGN)" TRACE=$(TRACE)
	@printf '%s\n' 'USER DESIGN CHECK PASS'

design-lint: require-design
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_LINT_DIR)
	@top=$$(cat $(DESIGN_LINT_DIR)/top.txt); \
	$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module "$$top" -f $(DESIGN_LINT_DIR)/sources.f

design-test: require-design
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_UNIT_DIR) --kind unit $(TEST_ARG)
	@top=$$(cat $(DESIGN_UNIT_DIR)/top.txt); \
	$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ $(VERILATOR_PROCASSINIT_FLAG) \
		--Mdir $(DESIGN_UNIT_DIR)/obj --top-module "$$top" \
		-f $(DESIGN_UNIT_DIR)/sources.f && \
	$(DESIGN_UNIT_DIR)/obj/V$$top

design-frame-test: require-design
	@mkdir -p $(dir $(FRAME_WAVE_FILE))
	@$(PYTHON) $(REGISTRY_TOOL) design-build --design $(DESIGN_MANIFEST) \
		--output-dir $(DESIGN_FRAME_DIR) --kind frame \
		--registry $(REGISTRY_MANIFEST) $(TEST_ARG) $(FRAME_TRACE_ARG)
	@top=$$(cat $(DESIGN_FRAME_DIR)/top.txt); \
	$(VERILATOR) --binary --timing --assert --Wall $(FRAME_TRACE_FLAGS) \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ -Wno-UNOPTFLAT $(VERILATOR_PROCASSINIT_FLAG) \
		--Mdir $(DESIGN_FRAME_DIR)/obj --top-module "$$top" \
		-f $(DESIGN_FRAME_DIR)/frame.f -f $(DESIGN_FRAME_DIR)/sources.f && \
	$(DESIGN_FRAME_DIR)/obj/V$$top

design-wave: require-design
	@command -v $(GTKWAVE) >/dev/null 2>&1 || (printf '%s\n' \
		'ERROR: GTKWave not found; install it or set GTKWAVE=<command>'; exit 127)
	@test -f "$(FRAME_WAVE_FILE)" || (printf '%s\n' \
		'ERROR: waveform not found: $(FRAME_WAVE_FILE)' \
		'Run make trace DESIGN=$(DESIGN)$(if $(TEST), TEST=$(TEST),) first.'; exit 2)
	@$(GTKWAVE) "$(FRAME_WAVE_FILE)" >/dev/null 2>&1 &
	@printf '%s\n' 'Opened waveform: $(FRAME_WAVE_FILE)'

# Compatibility aliases for the original public workflow.
create-design: create
lint-user: user-lint

clean:
	@rm -rf $(FRAME_ROOT)/build
