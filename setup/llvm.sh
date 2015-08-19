CONFIG=$HOME/.artiq_builder
BITNESS=linux-$(getconf LONG_BIT)
CURDIR=$PWD

if [ -f $CONFIG ]
then
	source $CONFIG
fi

if [ "$(which sudo)" = "" ]
then
	echo "You need to install sudo"
	exit 1
fi

mkdir -p $HOME/.mlabs

if [ "$BITNESS" = "linux-64" ]
then
	echo "Downloading and installing prebuilt 64 bit LLVM toolchain"
	archive="http://fehu.whitequark.org/files/llvm-or1k.tbz2"
	wget $archive
	cd packages && tar xf ../$(basename $archive)
	echo "export LD_LIBRARY_PATH=$PWD/packages/usr/lib/x86_64-linux-gnu:$PWD/packages/usr/local/x86_64-unknown-linux-gnu/or1k-elf/lib:\$LD_LIBRARY_PATH" >> $HOME/.mlabs/build_settings.sh
	echo "export PATH=$PWD/packages/usr/local/llvm-or1k/bin:$PWD/packages/usr/local/bin:$PWD/packages/usr/bin:\$PATH" >> $HOME/.mlabs/build_settings.sh
	echo "export LD_LIBRARY_PATH=$PWD/packages/usr/lib/x86_64-linux-gnu:$PWD/packages/usr/local/x86_64-unknown-linux-gnu/or1k-elf/lib:\$LD_LIBRARY_PATH" >> $HOME/.artiq_builder
	echo "export PATH=$PWD/packages/usr/local/llvm-or1k/bin:$PWD/packages/usr/local/bin:$PWD/packages/usr/bin:\$PATH" >> $HOME/.artiq_builder
else
	if [ "$(which git)" = "" ]
	then
		echo "You need to install git"
		exit 1
	fi

	if [ "$(which cmake)" = "" ]
	then
		echo "You need to install cmake"
		exit 1
	fi

	echo "Downloading and building 32 bit LLVM toolchain (this can take a long time)"
	git clone https://github.com/openrisc/llvm-or1k
	cd llvm-or1k/tools
	git clone https://github.com/openrisc/clang-or1k clang
	cd ..
	mkdir build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-or1k -DLLVM_TARGETS_TO_BUILD="OR1K;X86" -DCMAKE_BUILD_TYPE=Rel -DLLVM_ENABLE_ASSERTIONS=ON
	make -j4
	sudo make install
	echo "export PATH=/usr/local/llvm-or1k:\$PATH" >> $HOME/.mlabs/build_settings.sh
	echo "export PATH=/usr/local/llvm-or1k:\$PATH" >> $HOME/.artiq_builder
fi
cd $PWD
