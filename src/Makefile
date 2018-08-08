CC   = gcc
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =

ALL = bin2m12 lightmap normal tunnel cgedit2border cgedit2bin convert twister \
      light_map.bin bump.data tunnel.data border.data bg.data bitmap.data twister.data \
      up-kos.bin up-kos_emu.bin up-kos.m12 up-kos_emu.m12

all: $(ALL)

bin2m12: bin2m12.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^

lightmap: tools/lightmap.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

normal: tools/normal.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

tunnel: tools/tunnel.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

cgedit2border: tools/cgedit2border.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

cgedit2bin: tools/cgedit2bin.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

convert: tools/convert.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

twister: tools/dssim.c tools/charset.c tools/twister.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

light_map.bin:
	@$(ECHO) "GEN	LIGHTMAPS"
	@./lightmap ./data

bump.data:
	@$(ECHO) "GEN	BUMP DATA"
	@./normal ../data/20.png ./data/20.bin
	@./normal ../data/sphere0.png ./data/normal.bin
	@./normal ../data/skull2.png ./data/skull2.bin
	@./normal ../data/up.png ./data/up.bin

tunnel.data:
	@$(ECHO) "GEN	TUNNEL DATA"
	@./tunnel ./data
  
border.data:
	@$(ECHO) "GEN	BUMP BORDERS"
	@./cgedit2border ../data/frame00.txt ./data/frame00.bg
	@./cgedit2border ../data/frame01.txt ./data/frame01.bg
	@./cgedit2border ../data/frame02.txt ./data/frame02.bg
	@./cgedit2border ../data/frame03.txt ./data/frame03.bg

bg.data:
	@$(ECHO) "GEN	BG"
	@./cgedit2bin ../data/kings.txt ./data/kings.bg
	@./cgedit2bin ../data/cards.txt ./data/cards.bg
	@./cgedit2bin ../data/credit0000.txt ./data/credit0000_bg.bin
	@./cgedit2bin ../data/credit0001.txt ./data/credit0001_bg.bin
	@./cgedit2bin ../data/groquick.txt ./data/groquick.bin
  
bitmap.data:
	@$(ECHO) "GEN	BITMAP"
	@./convert ../data/credit00.png ./data/credit0000 2> /dev/null
	@./convert ../data/credit01.png ./data/credit0001 2> /dev/null
	
twister.data:
	@$(ECHO) "GEN	TWISTER"
	@./twister
	
up-kos.bin: up-kos.asm
	@$(ECHO) "RASM	$@"
	@cp ../data/ouagadougou.asm ./data/
	@$(RASM) $(RASMFLAGS) $^ -o $(basename $@)

up-kos_emu.bin: up-kos.asm
	@$(ECHO) "RASM	$@"
	@$(RASM) -DEMU=1 $(RASMFLAGS) $^ -o $(basename $@)
	
%.m12: %.bin
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ UP-KOS

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f bin2m12 lightmap normal tunnel cgedit2border cgedit2bin convert twister
	@rm -f up-kos.bin up-kos.m12 up-kos_emu.bin up-kos_emu.m12
	@rm -f ./data/*
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
	@find $(BUILD_DIR) -name "*.m12" -exec rm -f {} \;
