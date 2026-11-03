import json, sys, time, os, urllib.request, urllib.error
sys.path.insert(0, '.')
from probe_lib import file_info, UA
def download(url, path):
    for attempt in range(6):
        time.sleep(1.2)
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=60) as r, open(path, 'wb') as f:
                f.write(r.read())
            return True
        except urllib.error.HTTPError as e:
            if e.code != 429: print('  HTTP', e.code, url); return False
            time.sleep(10 * (attempt + 1))
    return False
