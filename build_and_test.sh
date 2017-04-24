#!/bin/bash

# XAUTHORITY must be set and DISPLAY must be set
# Usage: build_and_test.sh <branch> <hardwareId>
# XAUTHORITY must be accessible

# checkoutQtModule <module name> <branch>
function checkoutQtModule {
    git clone https://code.qt.io/qt/$1
    cd $1
    git checkout $2
    git rev-parse HEAD > ../$1_$2_sha1.txt
    cd ..
}

# buildQtModule <module name> <branch> <jobs>
function buildQtModule {
    checkoutQtModule $1 $2
    cd $1
    ../qtbase/bin/qmake
    make -j$3
    cd ..    
}

# compareSha1sAndAnnotate <module name> <branch>
function compareSha1sAndAnnotate {
    if [[ -e ../$1_$2_sha1.txt && -e $1_$2_sha1.txt ]]; then
	local new_sha1=$(cat $1_$2_sha1.txt)
	local old_sha1=$(cat ../$1_$2_sha1.txt)
	if [[ "$new_sha1" != "$old_sha1" ]]; then
	    qmlbenchrunner/annotate.py --title="$1 update" --tag="$1Update" --text="Updated $1 to $new_sha1 (previous was $old_sha1)" --branch="$2"
	fi
    fi

    if [[ -e $1_$2_sha1.txt ]]; then
	cp $1_$2_sha1.txt ../$1_$2_sha1.txt
    fi
}

# checkout and configure Qt Base
checkoutQtModule qtbase $1
cd qtbase
./configure -developer-build -nomake tests -nomake examples -release -opensource -confirm-license
make -j$3
cd ..

# other modules
buildQtModule qtdeclarative $1 $3
buildQtModule qtquickcontrols $1 $3
buildQtModule qtquickcontrols2 $1 $3
buildQtModule qtgraphicaleffects $1 $3

# qmlbench
git clone https://code.qt.io/qt-labs/qmlbench.git
cd qmlbench
git rev-parse HEAD > ../qmlbench_master_sha1.txt
../qtbase/bin/qmake
make -j8
./src/qmlbench --json --shell frame-count benchmarks/auto/creation/ benchmarks/auto/changes/ benchmarks/auto/js benchmarks/auto/animations > ../results.json
cd ..
qmlbenchrunner/run.py results.json $1 $2

if [ "$4" == "annotate" ]; then
    compareSha1sAndAnnotate qtbase $1
    compareSha1sAndAnnotate qtdeclarative $1
    compareSha1sAndAnnotate qtquickcontrols $1
    compareSha1sAndAnnotate qtquickcontrols2 $1
    compareSha1sAndAnnotate qtgraphicaleffects $1
    compareSha1sAndAnnotate qmlbench master
fi

rm -rf qtbase
rm -rf qtdeclarative
rm -rf qtquickcontrols
rm -rf qtquickcontrols2
rm -rf qtgraphicaleffects
rm -rf qmlbench
