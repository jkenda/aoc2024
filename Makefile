ODINC=../ODIN/Odin/odin

.PHONY: clean
.SECONDARY:

all: day_1 day_2 day_3

%: %.bin
	./$< input/$@

%.bin: src/%.odin
	$(ODINC) build $< -file

clean:
	'rm' -f *.bin
