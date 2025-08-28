NAME = $prog_name

# ---------- Helper scripts ----------

ORG2NW    := bash scripts/org2nw.sh
PRETANGLE := awk -f scripts/preTangle.awk

# ---------- Basic tangling ----------

all: $(NAME).$lang lang_actions

$(NAME).$lang: $(NAME).org
	$(ORG2NW) $(NAME).org | $(PRETANGLE) | notangle -R$(NAME).$lang > $(NAME).$lang

# ---------- Basic make subcommands ----------

.PHONY: doc clean

doc:
	make -C doc

clean:
	rm -f $(NAME) *.$lang
	make clean -C doc

# ---------- Language actions area ----------

