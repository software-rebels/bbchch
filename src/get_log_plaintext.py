###########
# This gets log of java-maven build jobs (for maven builds only)
# Input: All maven builds
# Output: Downloaded to data/builds
##########

import sys
import re
import argparse
import json
import os
import requests
import time
from time import gmtime, strftime


def resolve_none(i):
    if i is None:
        return 2
    else:
        return i


def download_job_log(output_dir, job_id):
    payload = {}
    url = "/".join(["https://api.travis-ci.org/jobs", job_id, "log"])
    # headers = {'content-type': 'application/json'}
    headers = {}
    while True:
        try:
            r = requests.get(url, headers=headers, params=payload)
            print(job_id, ':', r.status_code)
            filename = os.path.join(output_dir, str(job_id) + '.txt')
            with open(filename, 'w') as outfile:
                print(r.text, file=outfile)
            break
        except requests.exceptions.ConnectionError as err:
            print(strftime("%Y-%m-%d %H:%M:%S", gmtime()), ": Waiting for 5 mins before retrying")
            time.sleep(300)
            continue


def main(argv):
    argparser = argparse.ArgumentParser(description='Download Travis jobs given a build list or a job list.')
    group = argparser.add_mutually_exclusive_group(required=True)

    #  Eg: src_list="results/all_maven_build_ids.csv"
    #  Download jobs when a build list is given
    group.add_argument('-b', dest='build_list', help='input build id list')

    # Download jobs from a job list
    # Eg: job_list='results/all_maven_job_ids.csv'
    group.add_argument('-j', dest='job_list', help='input job id list')

    argparser.add_argument('--remote', action='store_true')

    args = argparser.parse_args()

    home_prefix = '/home/keheliya/dev/bbchch/'
    remote_prefix = '/mnt/bodiddley' + home_prefix
    if args.remote:
        data_loc = remote_prefix
    else:
        data_loc = home_prefix

    # We are only saving logs and json files in the server
    output_dir = data_loc+'data/logs'
    file_src = data_loc+'data/builds'

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(args)

    counter = 0
    if args.build_list:
        # Lists are stored locally
        src_list = home_prefix + args.build_list
        with open(src_list, 'r') as f:
            for line in f:
                if 'x' not in line:
                    build_id_line = line.strip()
                    counter += 1
                    with open(os.path.join(file_src, build_id_line+'.json'), 'r') as json_file:
                        results = json.load(json_file)
                        build_id = results["id"]
                        print(counter, '-', build_id)

                        build_result = resolve_none(results["result"])
                        build_status = resolve_none(results["status"])

                        for el in results['matrix']:
                            job_result = resolve_none(el['result'])
                            if int(job_result) == 0:
                                continue
                            job_id = str(el['id'])
                            print(job_id,job_result)
                            download_job_log(output_dir, job_id)

    elif args.job_list:
        # Lists are stored locally
        job_list = home_prefix + args.job_list
        with open(job_list, 'r') as f:
            for line in f:
                if 'x' not in line:
                    job_id = line.strip()
                    counter += 1
                    download_job_log(output_dir, job_id)

if __name__ == "__main__":
    main(sys.argv)