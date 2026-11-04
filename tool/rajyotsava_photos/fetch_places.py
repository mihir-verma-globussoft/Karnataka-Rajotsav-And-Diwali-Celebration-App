import json, os, re, sys
sys.path.insert(0, '.')
from fetch_lib import download
DISTRICT_IDS = {'Bengaluru South (Ramanagara)': 'ramanagara', 'Chikkaballapura': 'chikkaballapur'}
def district_id(d): return DISTRICT_IDS.get(d) or re.sub('[^a-z]+', '_', d.lower())
def slug(s): return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')
keep = json.load(open('places_keep.json'))
os.makedirs('dl_places', exist_ok=True)
credits = {}
for key, v in keep.items():
    d, p = key.split('|')
    app_key = district_id(d) + '|' + p
    path = os.path.join('dl_places', slug(app_key) + '.jpg')
    if os.path.exists(path) or download(v['thumb'], path):
        credits[app_key] = {k: v.get(k) for k in ('file', 'license', 'artist', 'page')}
json.dump(credits, open('dl_places/_credits.json', 'w'), indent=1)
print('downloaded', len(credits))
