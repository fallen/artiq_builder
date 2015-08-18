#!/bin/bash

CONFIG=$HOME/.artiq_builder
BITNESS=linux-$(getconf LONG_BIT)

if [ -f $CONFIG ]
then
	source $CONFIG
fi

if [ "$BITNESS" = "linux-32" ]
then
	MINICONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86.sh
else
	MINICONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
fi

if [ "$BITNESS" = "linux-32" ]
then
	ISE_URL=
else
	ISE_URL=
fi

mkdir -p $PWD/logs

echo "Downloading miniconda"
wget $MINICONDA_URL -O miniconda.sh
echo "Installing miniconda"
bash miniconda.sh -b -p $HOME/miniconda3
hash -r
conda config --set always_yes yes --set changeps1 no
conda update -q conda
conda info -a
conda install conda-build jinja2 anaconda-client
conda config --add channels https://conda.anaconda.org/m-labs/channel/dev

echo "Downloading ISE"
wget $ISE_URL -O ise.tar.gz.gpg
echo $ISE_PASSWORD | gpg --passphrase-fd 0 ise.tar.gz.gpg
sudo tar -C /opt -xzf ise.tar.gz

echo "Downloading Vivado"
wget $VIVADO_URL -O vivado.tar.gz.gpg
echo $VIVADO_PASSWORD | gpg --passphrase-fd 0 vivado.tar.gz.gpg
sudo tar -C /opt -xzf vivado.tar.gz

echo "Downloading Xilinx license"
wget http://sionneau.net/artiq/Xilinx/Xilinx.lic.gpg
echo $LICENSE_PASSWORD | gpg --passphrase-fd 0 Xilinx.lic.gpg
mkdir -p ~/.Xilinx
mv Xilinx.lic ~/.Xilinx/Xilinx.lic

git clone https://github.com/fallen/impersonate_macaddress
make -C impersonate_macaddress
mkdir -p $HOME/.mlabs
cat > $HOME/.mlabs/build_settings.sh << EOF
export MACADDR=$macaddress
export LD_PRELOAD=$PWD/impersonate_macaddress/impersonate_macaddress.so
EOF

echo "Downloading and installing or1k toolchain"
archives="http://fehu.whitequark.org/files/binutils-or1k.tbz2 http://fehu.whitequark.org/files/llvm-or1k.tbz2"
for a in $archives
do
  wget $a
  (cd packages && tar xf ../$(basename $a))
done


echo "export LD_LIBRARY_PATH=$PWD/packages/usr/lib/x86_64-linux-gnu:$PWD/packages/usr/local/x86_64-unknown-linux-gnu/or1k-elf/lib:\$LD_LIBRARY_PATH" >> $HOME/.mlabs/build_settings.sh
echo "export PATH=$PWD/packages/usr/local/llvm-or1k/bin:$PWD/packages/usr/local/bin:$PWD/packages/usr/bin:\$PATH" >> $HOME/.mlabs/build_settings.sh

