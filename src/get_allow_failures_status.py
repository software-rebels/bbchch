###########
# This gets failure status and some more info (for failed builds only)
# Input: All builds
# Output: Redirected to in results/allow_failure_status.csv
##########

import sys
import re
import json
import os

def resolve_none(i):
    if i is None:
        return 2
    else:
        return i

def main(argv):
    file_dest = "data/builds"
    for file in os.listdir(file_dest):
        if file.endswith(".json"):
            with open(os.path.join(file_dest, file), 'r') as json_file:
                results = json.load(json_file)
                build_id = results["id"]

                if results["compare_url"]:
                    p = re.compile(r'https://(github.com/|api.github.com/repos)(.*)/(.*)/.*$')
                    m = p.match(results["compare_url"])
                    repo_name = m.group(2)
                else:
                    repo_name = "null"

                build_result = resolve_none(results["result"])
                build_status = resolve_none(results["status"])

                for el in results['matrix']:
                    job_result = resolve_none(el['result'])
                    allow_failure = el['allow_failure']

                    output = [repo_name, build_id, build_result, build_status, job_result, allow_failure]
                    print(','.join(map(str, output)))


if __name__ == "__main__":
    main(sys.argv)