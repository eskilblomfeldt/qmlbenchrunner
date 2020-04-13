
param (
    [Parameter(Mandatory = $true)][string]$QtVersion = "dev",
    [Parameter(Mandatory = $true)][string]$MachineName = "UNKNOWN",
    [int]$BuildCores = 2,
    [switch]$Annotate,
    [string]$QtDeclarativeVersion = "",
    [string]$FlexBisonDir = "$PWD\flex_bison\"
)


function checkoutQtModule([string]$module, [string]$version) {
    git clone --progress https://code.qt.io/qt/$module
    cd $module
    git checkout $version
    git rev-parse HEAD > ([string]::Format("../{0}_{1}_sha1.txt", $module, $version))
    cd ..
}

function buildQtModule([string]$module, [string]$version, [int]$BuildCores) {
    checkoutQtModule $module $version
    cd $module
    if ($module -eq "qttools") {
        cd src/windeployqt
        ../../../qtbase/bin/qmake
        ../../../qmlbenchrunner/JOM/jom.exe -j $BuildCores
        cd ../..
    }
    else {
        ../qtbase/bin/qmake
        ../qmlbenchrunner/JOM/jom.exe -j $BuildCores
    }
    cd ..
}

function compareSha1sAndAnnotate([string]$module, [string]$version) {
    if ((Get-Content ([string]::Format("../{0}_{1}_sha1.txt", $module, $version))) -eq (Get-Content ([string]::Format("{0}_{1}_sha1.txt", $module, $version)))) {
        Set-Variable -Name "new_sha1" -Value (Get-Content ([string]::Format("{0}_{1}_sha1.txt", $module, $version)))
        Set-Variable -Name "old_sha1" -Value (Get-Content ([string]::Format("../{0}_{1}_sha1.txt", $module, $version)))

        if ($new_sha1 -ne $old_sha1) {
            python qmlbenchrunner/annotate.py --title="$module update" --tag="$moduleUpdate" --text="Updated $module to $new_sha1 (previous was $old_sha1)" --branch="$version"
        }
    }

    if ((Get-Content ([string]::Format("{0}_{1}_sha1.txt", $module, $version)))) {
        cp ([string]::Format("{0}_{1}_sha1.txt", $module, $version)) ([string]::Format("../{0}_{1}_sha1.txt", $module, $version))
    }
}

Set-Variable -Name "branch_label" -Value ([string]::Format("{0}+{1}", $QtVersion, $QtDeclarativeVersion))
Set-Variable -Name "qtdeclarative_branch" -Value $QtDeclarativeVersion
if ($qtdeclarative_branch.length -le 0) {
    $qtdeclarative_branch = $QtVersion
    $branch_label = $QtVersion
}

echo "Using $QtVersion as base and $qtdeclarative_branch for qtdeclarative. Using $branch_label as label in database."

#Configure Windows environment for building
pushd 'C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\Common7\Tools\'
cmd /c "VsDevCmd.bat&set" |
foreach {
    if ($_ -match "=") {
        $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
    }
}

$env:Path += ";$FlexBisonDir"

popd
Write-Host "`nVisual Studio 2017 Command Prompt variables set." -ForegroundColor Yellow


# checkout and configure Qt Base
checkoutQtModule qtbase $QtVersion
cd qtbase
./configure -developer-build -nomake tests -nomake examples -release -opensource -confirm-license -no-warnings-are-errors -opengl desktop
../qmlbenchrunner/JOM/jom.exe -j $BuildCores
cd ..

# other modules
buildQtModule qtdeclarative $qtdeclarative_branch $BuildCores
buildQtModule qtquickcontrols $QtVersion $BuildCores
buildQtModule qtquickcontrols2 $QtVersion $BuildCores
buildQtModule qtgraphicaleffects $QtVersion $BuildCores
buildQtModule qttools $QtVersion $BuildCores

# qmlbench
git clone --progress https://code.qt.io/qt-labs/qmlbench.git
cd qmlbench
git rev-parse HEAD > ../qmlbench_master_sha1.txt
../qtbase/bin/qmake
../qmlbenchrunner/JOM/jom.exe -j $BuildCores
cd ../qtbase/bin
./windeployqt.exe --qmldir ..\..\qmlbench\benchmarks ..\..\qmlbench\src\release\qmlbench.exe
cd ../..

cd qmlbench

if (Test-Path env:BADTESTS) {
    Remove-Item $env:BADTESTS -Recurse -Force
}

src/release/qmlbench.exe --json --shell frame-count benchmarks/auto/creation/ benchmarks/auto/changes/ benchmarks/auto/js benchmarks/auto/animations benchmarks/auto/bindings > ../results.json
cd ..
echo Label: $branch_label
python qmlbenchrunner/run.py results.json $branch_label $MachineName

if ($Annotate) {
    compareSha1sAndAnnotate qtbase $QtVersion
    compareSha1sAndAnnotate qtdeclarative $QtVersion
    compareSha1sAndAnnotate qtquickcontrols $QtVersion
    compareSha1sAndAnnotate qtquickcontrols2 $QtVersion
    compareSha1sAndAnnotate qtgraphicaleffects $QtVersion
    compareSha1sAndAnnotate qmlbench master
}

rm -PATH qtbase -Recurse -Force
rm -PATH qtdeclarative -Recurse -Force
rm -PATH qtquickcontrols -Recurse -Force
rm -PATH qtquickcontrols2 -Recurse -Force
rm -PATH qtgraphicaleffects -Recurse -Force
rm -PATH qttools -Recurse -Force
rm -PATH qmlbench -Recurse -Force