#!/bin/bash

# XAUTHORITY must be set and DISPLAY must be set
# Usage: build_and_test.sh <main branch> <hardwareId> <jobs> ["annotate"?] [qtdeclarative-branch]
# XAUTHORITY must be accessible

# checkoutQtModule <module name> <branch>
function checkoutQtModule {
    git clone --progress https://code.qt.io/qt/$1
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

branch_label="$1+$5"
qtdeclarative_branch=$5
if [[ -z $qtdeclarative_branch ]]; then
    qtdeclarative_branch=$1
    branch_label=$1
fi

echo "Using $1 as base and $qtdeclarative_branch for qtdeclarative. Using $branch_label as label in database."

# checkout and configure Qt Base
checkoutQtModule qtbase $1
cd qtbase
shopt -s nocasematch
if [[ "$1" == "5.6" ]] && [[ "$2" != *"macOS"* ]]; then
echo "Configuring with qt-xcb libraries because 5.6 requires this dependency and we\'re not sure it\'s installed on this system."
	./configure -developer-build -nomake tests -nomake examples -release -opensource -confirm-license -no-warnings-are-errors -qt-xcb
else
	./configure -developer-build -nomake tests -nomake examples -release -opensource -confirm-license -no-warnings-are-errors
fi
shopt -u nocasematch
make -j$3
cd ..

# other modules
buildQtModule qtdeclarative $qtdeclarative_branch $3
buildQtModule qtquickcontrols $1 $3
buildQtModule qtquickcontrols2 $1 $3
buildQtModule qtgraphicaleffects $1 $3

# qmlbench
git clone --progress https://code.qt.io/qt-labs/qmlbench.git
cd qmlbench
git rev-parse HEAD > ../qmlbench_master_sha1.txt
../qtbase/bin/qmake
make -j8
./src/qmlbench --json --shell frame-count benchmarks/auto/creation/ benchmarks/auto/changes/ benchmarks/auto/js benchmarks/auto/animations benchmarks/auto/bindings > ../results.json
cd ..
echo Label: $branch_label
qmlbenchrunner/run.py results.json $branch_label $2

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
