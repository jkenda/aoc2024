ODINC=Odin/odin

.PHONY: clean
.SECONDARY:

FILES=$(wildcard src/*.odin)
TARGETS=$(notdir $(basename $(FILES)))

all: $(TARGETS)

%: %.bin
	./$< input/$@

%.bin: src/%.odin $(ODINC)
	$(ODINC) build $< -file -o:speed

Odin/odin: Odin/Makefile
	cd Odin && make release

clean:
	'rm' -f *.bin
	'rm' Odin/odin
