# ZMM Software Build Script

OUT = ./Output
SOURCE = ./Source
ZASM = zasm

all: $(OUT)/ZMMBAS.COM $(OUT)/TPAINTEG.COM $(OUT)/IDEINTEG.COM 

$(OUT)/%.COM: $(SOURCE)/%.asm
	$(ZASM) $(SOURCE)/$*.asm -u -w -b $(OUT)/$*.COM
	
clean:
	rm $(OUT)/*