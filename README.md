# ARTIQ builder

ARTIQ builder is currently used to build conda packages (and upload them) for ARTIQ on 32-bit Windows and 32-bit Linux (64-bit Linux packages are done by Travis-ci).

# How to install on Linux

`$ git clone https://github.com/fallen/artiq_builder`

Then install all ARTIQ conda package build time dependencies:

- git
- ISE and Vivado (only needed for Linux builds)
- miniconda for python 3.4
- or1k LLVM  (Follow http://m-labs.hk/artiq/manual/installing.html#installing-from-source "Install LLVM and Clang:")
```
$ conda config --set always_yes yes --set changeps1 no
$ conda install conda-build jinja2 anaconda-client
```
set up artiq_builder.sh as a cron job:

`$ crontab -e`

Add this line to the cron file:

`  * *  *   *   *     $HOME/artiq_builder/artiq_builder.sh > $HOME/artiq_builder/logs/$(date +"\%F-\%T").txt 2>&1`

Alternatively, there is an experimental (and poorly tested) automatic installer: 

`$ ./setup.sh`

# How to install on 32-bit Windows

- Install cygwin
- Install (via cygwin): 
  - cron: Vixie's cron
  - cygrunsrv: NT/W2K service initiator
  - git
- miniconda for 32-bit Windows and python 3.4
- Configure Vixie's cron as follows: http://www.davidjnice.com/cygwin_cron_service.html
```
$ conda config --set always_yes yes --set changeps1 no
$ conda install conda-build jinja2 anaconda-client
```
set up artiq_builder.sh as a cron job:

`$ crontab -e`

Add this line to the cron file:

`  * *  *   *   *     $HOME/artiq_builder/artiq_builder.sh > $HOME/artiq_builder/logs/$(date +"\%F-\%T").txt 2>&1`
