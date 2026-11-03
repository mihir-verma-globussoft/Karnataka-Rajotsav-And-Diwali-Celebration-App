"""Find free Commons photos for the CSV places, 50 titles per request."""
import csv, json, re, sys
sys.path.insert(0, '.')
from probe_lib import api
rows = list(csv.DictReader(open(sys.argv[1], encoding='utf-8-sig')))
GENERIC = {'temple','fort','hills','hill','lake','falls','dam','beach','park','palace','church','sanctuary','national',
           'wildlife','bird','the','of','and','sri','shri','matha','mutt','museum','garden','gardens','cave','caves',
           'island','betta','gudi','reservoir','tank','statue','viewpoint','village','heritage','karnataka','india'}
def words(s): return {w for w in re.findall(r'[a-z]+', s.lower()) if w not in GENERIC and len(w) > 2}
def chunks(xs, n=50):
    for i in range(0, len(xs), n): yield xs[i:i+n]
def page_images(titles):
    """title -> (resolved title, page image file) for existing pages."""
    out = {}
    for batch in chunks(titles):
        d = api({'action':'query','titles':'|'.join(batch),'prop':'pageimages','piprop':'name','redirects':1})
        q = d['query']
        alias = {}
        for n in q.get('normalized', []) + q.get('redirects', []): alias[n['to']] = alias.get(n['from'], n['from'])
        for p in q['pages']:
            if p.get('missing') or 'pageimage' not in p: continue
            src = p['title']
            while src in alias: src = alias[src]
            out[src] = (p['title'], p['pageimage'])
    return out
names = sorted({r['Place'] for r in rows})
found = page_images(names)
print('exact titles with images:', len(found), 'of', len(names), flush=True)
results = {}
for r in rows:
    key = r['District'] + '|' + r['Place']
    hit = found.get(r['Place']) or found.get(r['Place'][:1].upper() + r['Place'][1:])
    if hit: results[key] = {'title': hit[0], 'file': hit[1], 'how': 'exact'}
# Search only for the rest, and keep a hit only if its title shares a distinctive word.
for r in rows:
    key = r['District'] + '|' + r['Place']
    if key in results: continue
    d = api({'action':'query','list':'search','srsearch': r['Place'] + ' ' + r['District'],'srlimit':3})
    for h in d['query']['search']:
        if words(h['title']) & words(r['Place']):
            results[key] = {'title': h['title'], 'how': 'search'}; break
    print(('ok ' if key in results else '-- ') + key + ' -> ' + str(results.get(key, {}).get('title')), flush=True)
need = sorted({v['title'] for v in results.values() if 'file' not in v})
for t, (title, f) in page_images(need).items():
    for v in results.values():
        if v.get('title') == t and 'file' not in v: v['file'] = f
# Licence check on Commons, 50 files per request.
files = sorted({v['file'] for v in results.values() if v.get('file')})
info = {}
for batch in chunks(files):
    d = api({'action':'query','titles':'|'.join('File:'+f for f in batch),'prop':'imageinfo','iiprop':'url|extmetadata','iiurlwidth':360}, host='commons.wikimedia.org')
    norm = {n['to']: n['from'] for n in d['query'].get('normalized', [])}
    for p in d['query']['pages']:
        if 'imageinfo' not in p: continue
        ii = p['imageinfo'][0]; m = ii.get('extmetadata', {})
        g = lambda k: (m.get(k) or {}).get('value', '')
        name = norm.get(p['title'], p['title'])[5:]
        info[name.replace(' ', '_')] = {'thumb': ii.get('thumburl'), 'page': ii.get('descriptionurl'), 'license': g('LicenseShortName'), 'artist': g('Artist'), 'nonfree': g('NonFree')}
for key, v in results.items():
    i = info.get((v.get('file') or '').replace(' ', '_'))
    if i: v.update(i)
json.dump(results, open(sys.argv[2], 'w'), indent=1)
ok = [k for k, v in results.items() if v.get('license') and not v.get('nonfree') and v.get('thumb')]
print('free photos:', len(ok), 'of', len(rows))
