###########
# This gets the event type and tag information for each build
# Input: results/failed_build_ids.csv
# Output: Redirected to results/job_failure_level.csv
##########


import http.client
import argparse
import sys
import re
import requests,json
import os
import csv
import time
from time import gmtime, strftime

def main(argv):
    # print('.....')
    # print(os.getcwd())
    os.chdir(sys.path[0])
    os.chdir('..')
    # print(os.getcwd())
    argparser = argparse.ArgumentParser(description='-s problematic_builds.csv')
    argparser.add_argument('-s', dest='src_list', default='results/problematic_builds.csv',
                           help='input build id list')

    args = argparser.parse_args()

    src_list = ''
    if args.src_list:
        src_list = args.src_list


    counter = 0

    with open(src_list, 'r') as f:
        for line in f:
            if 'x' not in line:
                build_id = line.strip()
                counter += 1
                payload = {}

                tag = 'null'

                url = "/".join(["https://api.travis-ci.org/v3/build", build_id])
                headers = {'content-type': 'application/json'}
                while True:
                    try:
                        r = requests.get(url, headers=headers, params=payload)
                        break
                    except requests.exceptions.ConnectionError as err:
                        print(strftime("%Y-%m-%d %H:%M:%S", gmtime()),": Waiting for 5 mins before retrying")
                        time.sleep(300)
                        continue

                results = r.json()

                if results["event_type"]:
                    event_type = results["event_type"]

                if results["tag"] and results["tag"]["name"]:
                    tag = results["tag"]["name"]

                output = [build_id,event_type,tag]
                print(','.join(map(str, output)))


if __name__ == "__main__":
    main(sys.argv)