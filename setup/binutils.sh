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
	echo "Downloading and installing prebuilt 64 bit binutils toolchain"
	archive="http://fehu.whitequark.org/files/binutils-or1k.tbz2"
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
	fi
	echo "Downloading and building 32 bit binutils toolchain"
	git clone https://github.com/m-labs/artiq
	wget https://ftp.gnu.org/gnu/binutils/binutils-2.25.1.tar.bz2
	tar xvf binutils-2.25.1.tar.bz2
	rm binutils-2.25.1.tar.bz2
	cd binutils-2.25.1
	patch -p1 < ../artiq/misc/binutils-2.25.1-or1k-R_PCREL-pcrel_offset.patch
	rm -rf ../artiq
	mkdir build
	cd build
	../configure --target=or1k-linux --prefix=/usr/local
	make -j4
	sudo make install
	echo "export PATH=/usr/local/bin:\$PATH" >> $HOME/.mlabs/build_settings.sh
	echo "export PATH=/usr/local/bin:\$PATH" >> $HOME/.artiq_builder
fi
cd $PWD
