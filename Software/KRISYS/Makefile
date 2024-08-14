# ZMM Software Build Script

OUT = ./Output
SOURCE = ./Source
ZASM = zasm

all: $(OUT)/KCOLECO.COM $(OUT)/KSG1000.COM

$(OUT)/%.COM: $(SOURCE)/*.asm
	$(ZASM) $(SOURCE)/$*.asm -u -w -b $(OUT)/$*.COM
	
clean:
	rm $(OUT)/*