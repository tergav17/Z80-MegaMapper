# ZMM Software Build Script

OUT = ./Output
SOURCE = ./Source
ZASM = zasm

all: $(OUT)/KMSX.COM $(OUT)/KSG1000.COM  $(OUT)/KCOLECO.COM

$(OUT)/%.COM: $(SOURCE)/*.asm
	$(ZASM) $(SOURCE)/$*.asm -u -w -b $(OUT)/$*.COM
	
clean:
	rm $(OUT)/*