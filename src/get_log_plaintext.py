###########
# This gets log of java-maven build jobs (for maven builds only)
# Input: All maven builds
# Output: Downloaded to data/builds
##########

import sys
import re
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

def main(argv):
    home_prefix = '/home/keheliya/dev/bbchch/'

    output_dir = home_prefix+'data/logs'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    counter = 0
    file_src = home_prefix+'data/builds'
    src_list = home_prefix+'results/all_maven_build_ids.csv'
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
                        payload = {}
                        url = "/".join(["https://api.travis-ci.org/jobs", job_id,"log"])
                        # headers = {'content-type': 'application/json'}
                        headers = {}
                        while True:
                            try:
                                r = requests.get(url, headers=headers, params=payload)
                                filename = os.path.join(output_dir, str(job_id) + '.txt')
                                with open(filename, 'w') as outfile:
                                    print(r.text, file=outfile)
                                break
                            except requests.exceptions.ConnectionError as err:
                                print(strftime("%Y-%m-%d %H:%M:%S", gmtime()), ": Waiting for 5 mins before retrying")
                                time.sleep(300)
                                continue




if __name__ == "__main__":
    main(sys.argv)