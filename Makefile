ODINC=../ODIN/Odin/odin

all: day_1

%: src/%.odin
	$(ODINC) run $< -file -- input/$@
