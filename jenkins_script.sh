mkdir $BUILD_NUMBER
cd $BUILD_NUMBER
git clone https://github.com/eskilblomfeldt/qmlbenchrunner.git

export XAUTHORITY=/home/eskil/.Xauthority
export DISPLAY=:1
qmlbenchrunner/build_and_test.sh 5.9 eskil_linux_foucault
