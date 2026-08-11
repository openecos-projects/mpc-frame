RTL_FILELIST := $(FRAME_ROOT)/rtl/filelist.f
REGRESSION_TOOL := $(FRAME_ROOT)/scripts/run_regression.py
REFERENCE_ROOT := $(FRAME_ROOT)/dev/reference/sim
REFERENCE_SIM_DIR := $(REFERENCE_ROOT)/dv/verilator
REFERENCE_FRAME_FILELIST := $(REFERENCE_ROOT)/hw/filelist/frame.f
REFERENCE_IMAGE ?= $(REFERENCE_ROOT)/sw/bootrom/hello/retrosoc_fw.bin
CONTROL_TEST_DIR := $(FRAME_ROOT)/build/control-test
CONTENTION_TEST_DIR := $(FRAME_ROOT)/build/contention-test
DOCS_SITE_ROOT := $(FRAME_ROOT)/dev/site
DOCS_SITE_SOURCE := $(FRAME_ROOT)/build/docs-site
DESIGN_ID ?=
USER_KIT_OUTPUT ?= $(FRAME_ROOT)/build/user-kit

.PHONY: dev-help require-design-id lint registry-filelist registry-check \
	registry-generate integrate-design manifest-test stage5-test stage9-test \
	frame-test regression-fast regression control-test io-contention-test \
	reference-verilate reference-sim reference-test docs-check docs-site-install \
	docs-site-prepare docs-site-dev docs-site-build docs-site-preview \
	docs-site-check export-user-kit dev-clean

dev-help:
	@printf '%s\n' 'mpc-frame maintainer commands (make -f Makefile.dev <target>)'
	@printf '%s\n' '  lint | stage9-test | regression-fast | regression'
	@printf '%s\n' '  registry-check | registry-generate | integrate-design'
	@printf '%s\n' '  docs-site-check | reference-test | export-user-kit'

require-design-id:
	@test -n "$(DESIGN_ID)" || (printf '%s\n' \
		'ERROR: DESIGN_ID is required for maintainer integration (1..127)'; exit 2)

registry-filelist:
	@$(PYTHON) $(REGISTRY_TOOL) registry-filelist \
		--registry $(REGISTRY_MANIFEST) --filelist $(REGISTRY_FILELIST)

registry-check:
	@$(PYTHON) $(REGISTRY_TOOL) check-registry \
		--registry $(REGISTRY_MANIFEST) --output $(REGISTRY_RTL)

registry-generate:
	@$(PYTHON) $(REGISTRY_TOOL) generate-registry \
		--registry $(REGISTRY_MANIFEST) --output $(REGISTRY_RTL) \
		--filelist $(REGISTRY_FILELIST)

integrate-design: require-design require-design-id
	@$(PYTHON) $(REGISTRY_TOOL) integrate-design --design $(DESIGN_MANIFEST) \
		--id $(DESIGN_ID) --registry $(REGISTRY_MANIFEST)
	@$(MAKE) -f $(FRAME_MAKEFILE) registry-generate
	@$(MAKE) -f $(FRAME_MAKEFILE) registry-check
	@$(MAKE) -f $(FRAME_MAKEFILE) design-frame-test DESIGN=$(DESIGN) $(if $(TEST),TEST=$(TEST),)

lint: registry-filelist registry-check
	@$(VERILATOR) --lint-only --timing --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		--top-module FrameTop -f $(RTL_FILELIST)

manifest-test:
	@$(PYTHON) -m unittest discover -s dev/tests/registry -p 'test_*.py'

stage5-test: stage9-test

stage9-test: manifest-test
	@$(PYTHON) $(FRAME_ROOT)/scripts/test_user_template.py

frame-test: require-design
	@$(PYTHON) $(REGRESSION_TOOL) --root $(FRAME_ROOT) --trace $(TRACE) frame \
		--design $(DESIGN) $(TEST_ARG)

regression-fast:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(FRAME_ROOT) --trace $(TRACE) \
		regression --mode fast

regression:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(FRAME_ROOT) --trace $(TRACE) \
		regression --mode full

control-test:
	@mkdir -p $(CONTROL_TEST_DIR)
	@$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ $(VERILATOR_PROCASSINIT_FLAG) \
		--Mdir $(CONTROL_TEST_DIR) --top-module FrameControlTb \
		rtl/FrameClockGate.sv rtl/FrameDesignControl.sv rtl/DesignIoMux.sv \
		dev/tests/control/FrameControlTb.sv
	@$(CONTROL_TEST_DIR)/VFrameControlTb

io-contention-test:
	@mkdir -p $(CONTENTION_TEST_DIR)
	@$(VERILATOR) --binary --timing --assert --Wall \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME \
		-Wno-BLKSEQ $(VERILATOR_PROCASSINIT_FLAG) \
		--Mdir $(CONTENTION_TEST_DIR) --top-module FrameIoContentionTb \
		rtl/FrameClockGate.sv rtl/FrameDesignControl.sv rtl/DesignIoMux.sv \
		dev/tests/frame/FrameIoContentionRegistry.sv FrameTop.sv \
		dev/tests/frame/FrameIoContentionTb.sv
	@$(CONTENTION_TEST_DIR)/VFrameIoContentionTb

reference-verilate: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) verilate \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=$(TRACE)

reference-sim: registry-filelist registry-check
	@$(MAKE) -C $(REFERENCE_SIM_DIR) sim \
		TOP=FrameTop RTL_FILELIST=$(REFERENCE_FRAME_FILELIST) TRACE=$(TRACE) \
		BOOTROM_IMAGE=$(REFERENCE_IMAGE) $(REFERENCE_SIM_ARGS)

reference-test:
	@$(PYTHON) $(REGRESSION_TOOL) --root $(FRAME_ROOT) --trace $(TRACE) reference

docs-check:
	@$(PYTHON) $(FRAME_ROOT)/scripts/check_docs.py

docs-site-install:
	@npm --prefix $(DOCS_SITE_ROOT) ci

docs-site-prepare:
	@$(PYTHON) $(FRAME_ROOT)/scripts/prepare_docs_site.py \
		--root $(FRAME_ROOT) --output $(DOCS_SITE_SOURCE)

docs-site-dev: docs-site-prepare
	@npm --prefix $(DOCS_SITE_ROOT) run dev

docs-site-build: docs-site-prepare
	@npm --prefix $(DOCS_SITE_ROOT) run build

docs-site-preview:
	@npm --prefix $(DOCS_SITE_ROOT) run preview

docs-site-check: docs-check docs-site-build

export-user-kit:
	@$(PYTHON) $(FRAME_ROOT)/scripts/export_user_kit.py \
		--root $(FRAME_ROOT) --output $(USER_KIT_OUTPUT)

dev-clean: clean
	@rm -rf $(REFERENCE_ROOT)/build
