#!/usr/bin/env python3

import os
import sys
import subprocess
import logging
import requests
import json

HOSTNAME = "10.213.255.45:8086"
#HOSTNAME = "localhost:8086"

def submit_output(output, branch, hardwareId):
    tree = json.loads(output)
    for key in tree:
        if key.endswith(".qml") and "average" in tree[key]:
            mean = tree[key]["average"]
            standardDeviation = tree[key]["standard-deviation-all-samples"]
            coefficientOfVariation = standardDeviation / mean if mean > 0.0 else 0.0
            basename = key.split("/")[-1]
            tags = ('branch=' + branch, 'benchmark=' + basename, 'hardwareId=' + hardwareId)
            fields = ('mean=' + str(mean),
                      'coefficientOfVariation=' + str(coefficientOfVariation),
                      )

            data = 'benchmarks,%s %s' % (','.join(tags), ','.join(fields))
            result = requests.post("http://%s/write?db=qmlbench" % HOSTNAME, data=data.encode('utf-8'))
            print(data)
            print(result)

def run_benchmark(filename, branch, hardwareId):
    output = subprocess.check_output(["cat", filename])
    submit_output(output.decode("utf-8"), branch, hardwareId)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help = "The .json file to post")
    parser.add_argument("branch", help = "The Qt branch tested")
    parser.add_argument("hardwareId", help = "Our unique hardware ID (e.g. linux_imx6_eskil)")
    args = parser.parse_args(sys.argv[1:])
    print("Posting results: " + args.filename)
    run_benchmark(args.filename, args.branch, args.hardwareId)
