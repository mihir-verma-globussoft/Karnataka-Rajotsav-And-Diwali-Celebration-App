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
kind, src, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(src))
# Manual picks for stars without a page photo (checked by eye afterwards).
manual = {'shankar_nag': 'Bust of Shankar Nag in Indiranagar.jpg', 'darshan': 'Darshan Thoogudeepa (1).jpg',
          'yash': 'Yash Kannada actor.jpg', 'aarathi': 'Aarathi (actress).jpg'} if kind == 'stars' else {}
for key, name in manual.items():
    info = file_info(name)
    if info: data[key] = {'title': key, 'file': name, **info}
os.makedirs(outdir, exist_ok=True)
credits = {}
for key, rec in data.items():
    if not rec.get('license') or rec.get('nonfree') or not rec.get('thumb'): continue
    path = os.path.join(outdir, key + '.jpg')
    if download(rec['thumb'], path):
        credits[key] = {k: rec.get(k) for k in ('file', 'license', 'artist', 'page')}
        print('got', key)
json.dump(credits, open(os.path.join(outdir, '_credits.json'), 'w'), indent=1)
