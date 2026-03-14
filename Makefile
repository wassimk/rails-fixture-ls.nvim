PANVIMDOC_DIR ?= /tmp/panvimdoc

.PHONY: lint panvimdoc docs

lint:
	stylua --check lua/ lsp/

panvimdoc:
	@if [ ! -d "$(PANVIMDOC_DIR)" ]; then \
		git clone --depth 1 https://github.com/kdheepak/panvimdoc $(PANVIMDOC_DIR); \
	fi

docs: panvimdoc
	$(PANVIMDOC_DIR)/panvimdoc.sh \
		--project-name rails-fixture-ls.nvim \
		--input-file README.md \
		--vim-version "NVIM v0.11.0" \
		--toc true \
		--treesitter true \
		--doc-mapping-project-name false
