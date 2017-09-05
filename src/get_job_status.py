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
    argparser = argparse.ArgumentParser(description='-s failed_build_ids.csv')
    argparser.add_argument('-s', dest='src_list', default='results/failed_build_ids.csv',
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

                time.sleep(1)
                results = r.json()
                error_sum = 0
                for el in results['matrix']:
                    if el['result']:
                        error_sum += el['result']

                p = re.compile(r'https://github.com/(.*)/(.*)/.*$')
                m = p.match(results["compare_url"])
                output = [results["id"], results["repository_id"], m.group(1), len(results['matrix']), error_sum]
                print(','.join(map(str, output)))


if __name__ == "__main__":
    main(sys.argv)