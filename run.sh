#!/bin/bash
#set -e
# Clone kernel
echo -e "$green << cloning kernel >> \n $white"
git clone --depth=1 https://github.com/omnitrix21/kernel_xiaomi_sm6150 13
cd 13

KERNEL_DEFCONFIG=sweet_defconfig
date=$(date +"%Y-%m-%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
export zipname="OmnitrixKernel-FourArms-OSS-sweet-${date}.zip"

# Tool Chain
echo -e "$green << cloning gcc from arter >> \n $white"
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)

# Clang
echo -e "$green << cloning clang >> \n $white"
git clone -b master --single-branch --depth="1" https://gitlab.com/itsshashanksp/android_prebuilts_clang_host_linux-x86_clang-r487747c "$PWDIR"/../clang
export PATH="$HOME/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')


# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out CC=clang
make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee error.log
                                                  
export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

find out/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb" ]; then
	echo "------ Finishing  Build ------"
	git clone -q https://github.com/Sweet-stuff/AnyKernel3
	cp out/arch/arm64/boot/Image.gz AnyKernel3
	cp out/arch/arm64/boot/dtb AnyKernel3
	cp out/arch/arm64/boot/dtbo.img AnyKernel3
	rm -f *zip
	cd AnyKernel3
	sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
	zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo ""
	echo -e ${zipname} " is ready!"
	echo ""
else
	echo -e "\n Compilation Failed!"
fi

# Upload to Gdrive
echo -e "$green << Uploading to Gdrive>> \n $white"
gdrive upload ${zipname}
echo -e "$green << Uploading Done>> \n $white"

