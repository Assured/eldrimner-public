.PHONY: help push-src generate-iso clean purge all

EUBUNTU = "http://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-amd64.iso"

help:
	@echo "<make all> Create an ISO from current src and install script"
	@echo "<make init> download Ubuntu ISO, extract into ./ubuntu-iso/"
	@echo "<make push-src> push the files in ./src/ into the Ubuntu installer"
	@echo "<make generate-iso> render the Ubuntu Server ISO and store in ./output/"
	@echo "<make clean> remove ./output/ and ./ubuntu-iso/ files"
	@echo "<make purge> make clean and remove ubuntu.iso"

all: push-src generate-iso
	@echo "[INFO] ISO stored in ./output/ubuntu.iso"

init: ubuntu.iso
	@echo "[INFO] Initializing..."
	mkdir ./output ./ubuntu-iso ./temp
	@echo "[INFO] Needs sudo to mount and extract original ISO"
	sudo mount -ro loop ./ubuntu.iso ./temp/
	rsync -rlptv ./temp/ ./ubuntu-iso/
	sudo umount ./temp
	sudo chmod -R u+w ./ubuntu-iso/
	touch init

ubuntu.iso:
	wget -O ubuntu.iso $(EUBUNTU)

push-src: init
	tar cvf ./src/eldrimner/install.tar ./install/*
	rsync -rlptv ./src/ ./ubuntu-iso/

generate-iso: init
	@echo "[INFO] Generating Eldrimner Ubuntu ISO into ./output/"
	mkisofs -U -A "Eldrimner" -V "Eldrimner" -volset "Eldrimner" -J -joliet-long -r -v -T -o ./output/ubuntu-eldrimner.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot ./ubuntu-iso/
	isohybrid ./output/ubuntu-eldrimner.iso

clean:
	@echo "[WARN] Deleting files in ./output/ and ./ubuntu-iso/"
	rm -rf ./output ./ubuntu-iso ./init ./temp

purge: clean
	@echo "[WARN] Deleting all files from init"
	rm ubuntu.iso
