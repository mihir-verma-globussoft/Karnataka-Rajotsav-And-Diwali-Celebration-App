"""Keep only confident place photos from places2_out.json -> places_keep.json.

Rules: a search match must share a distinctive word with the place name
that is not just the district or a town shared by several places; one
photo per place (the same place in two districts may share). Maps,
locators, flags and logos are dropped later in fetch_places.py's output
review (see README)."""
import collections, json, re
GENERIC = {'temple','fort','hills','hill','lake','falls','dam','beach','park','palace','church','sanctuary','national',
           'wildlife','bird','the','of','and','sri','shri','matha','mutt','museum','garden','gardens','cave','caves',
           'island','betta','gudi','reservoir','tank','statue','viewpoint','village','heritage','karnataka','india',
           'district','city','town'}
def words(s): return {w for w in re.findall(r'[a-z]+', s.lower()) if w not in GENERIC and len(w) > 2}
r = json.load(open('places2_out.json'))
by_district = collections.defaultdict(list)
for k in r: by_district[k.split('|')[0]].append(k.split('|')[1])
local = {d: {w for w, c in collections.Counter(w for p in ps for w in words(p)).items() if c >= 2}
         for d, ps in by_district.items()}
keep = {}
for k, v in r.items():
    if not (v.get('license') and not v.get('nonfree') and v.get('thumb')): continue
    d, p = k.split('|')
    if v['how'] == 'search' and not ((words(v['title']) & words(p)) - words(d) - local[d]): continue
    keep[k] = v
byfile = collections.defaultdict(list)
for k, v in keep.items(): byfile[v['file']].append(k)
for ks in byfile.values():
    ks.sort(key=lambda k: (keep[k]['how'] != 'exact', len(k)))
    for k in ks[1:]:
        if k.split('|')[1] != ks[0].split('|')[1]: keep.pop(k)
json.dump(keep, open('places_keep.json', 'w'), indent=1)
print('kept', len(keep))
