#!/usr/bin/env python3

import os
import sys
import subprocess
import logging
import requests
import json

HOSTNAME = "10.213.255.45"

def submit_output(output, branch, qtBaseHead, qtDeclarativeHead):
    tree = json.loads(output)
    gpuVendor = tree["opengl"]["vendor"]
    driverVersion = tree["opengl"]["version"]
    qtVersion = tree["qt"]
    osVersion = tree["os"]["prettyProductName"].replace(' ', '.')
    for key in tree:
        if key.endswith(".qml"):
            mean = tree[key]["average"]
            standardDeviation = tree[key]["standard-deviation-all-samples"]
            coefficientOfVariation = standardDeviation / mean if mean > 0.0 else 0.0
            basename = key.split("/")[-1]
            tags = ('qtVersion=' + qtVersion, 'osVersion=' + osVersion, 'branch=' + branch)
            fields = ('mean=' + str(mean),
                      'coefficientOfVariation=' + str(coefficientOfVariation),
                      'qtBaseHead="' + qtBaseHead + '"',
                      'qtDeclarativeHead="' + qtDeclarativeHead + '"',)

            data = '%s,%s %s' % (basename, ','.join(tags), ','.join(fields))
            result = requests.post("http://10.213.255.45:8086/write?db=qmlbench", data=data.encode('utf-8'))
            print(data)
            print(result)

    
def run_benchmark(filename, branch, qtBaseHead, qtDeclarativeHead):
    output = subprocess.check_output(["cat", filename])
    submit_output(output.decode("utf-8"), branch, qtBaseHead, qtDeclarativeHead)
    
    
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help = "The .json file to post")
    parser.add_argument("branch", help = "The Qt branch tested")
    parser.add_argument("qtBaseHead", help = "The current HEAD of Qt Base")
    parser.add_argument("qtDeclarativeHead", help = "The current HEAD of Qt Declarative")
    args = parser.parse_args(sys.argv[1:])
    print("Posting results: " + args.filename)
    run_benchmark(args.filename, args.branch, args.qtBaseHead, args.qtDeclarativeHead)
    
    
