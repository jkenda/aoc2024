ODINC=../ODIN/Odin/odin

.PHONY: clean
.SECONDARY:

all: day_1 day_2 day_3 day_4 day_5 day_6 day_7 day_8

%: %.bin
	./$< input/$@

%.bin: src/%.odin
	$(ODINC) build $< -file -o:speed

clean:
	'rm' -f *.bin
