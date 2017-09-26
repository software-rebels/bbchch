###########
# Input: results/all_build_ids.csv
# Output: stored in data/builds as json files (everything in the remote server and 104 in the local test setup)
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
    argparser = argparse.ArgumentParser(description='-s all_build_ids.csv')
    argparser.add_argument('-s', dest='src_list', default='results/all_build_ids.csv',
                           help='input build id list')

    args = argparser.parse_args()

    directory = 'data/builds'
    src_list = ''
    if args.src_list:
        src_list = args.src_list

    if not os.path.exists(directory):
        os.makedirs(directory)

    counter = 0

    with open(src_list, 'r') as f:
        for line in f:
            if 'x' not in line:
                build_id = line.strip()
                counter += 1
                payload = {}

                url = "/".join(["https://api.travis-ci.org/builds", build_id])
                headers = {'content-type': 'application/json'}
                while True:
                    try:
                        r = requests.get(url, headers=headers, params=payload)
                        break
                    except requests.exceptions.ConnectionError as err:
                        print(strftime("%Y-%m-%d %H:%M:%S", gmtime()),": Waiting for 5 mins before retrying")
                        time.sleep(300)
                        continue

                # time.sleep(1)
                results = r.json()
                build_id = results["id"]
                print(counter, '-', build_id)
                filename = os.path.join(directory, str(build_id)+'.json')
                with open(filename, 'w') as outfile:
                    json.dump(results, outfile)

if __name__ == "__main__":
    main(sys.argv)