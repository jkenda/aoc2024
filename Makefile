ODINC=../ODIN/Odin/odin

.PHONY: clean
.SECONDARY:

FILES=$(wildcard src/*.odin)
TARGETS=$(notdir $(basename $(FILES)))

all: $(TARGETS)

%: %.bin
	./$< input/$@

%.bin: src/%.odin
	$(ODINC) build $< -file -o:speed

clean:
	'rm' -f *.bin
