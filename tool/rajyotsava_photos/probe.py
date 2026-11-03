import json, sys, time, urllib.error, urllib.parse, urllib.request
UA = 'GlobusHabbaApp/1.0 (internal build tool)'
def api(params, host='en.wikipedia.org'):
    params = dict(params, format='json', formatversion='2')
    url = f'https://{host}/w/api.php?' + urllib.parse.urlencode(params)
    for attempt in range(6):
        time.sleep(1.5)
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429: raise
            time.sleep(10 * (attempt + 1))
    raise RuntimeError('rate limited: ' + url)
def page_image(title):
    d = api({'action':'query','titles':title,'prop':'pageimages','piprop':'name','redirects':1})
    p = d['query']['pages'][0]
    return p.get('title'), p.get('pageimage')
def file_info(name):
    d = api({'action':'query','titles':'File:'+name,'prop':'imageinfo','iiprop':'url|extmetadata','iiurlwidth':480}, host='commons.wikimedia.org')
    p = d['query']['pages'][0]
    if 'imageinfo' not in p: return None  # not on Commons (local, usually non-free)
    ii = p['imageinfo'][0]; m = ii.get('extmetadata', {})
    g = lambda k: (m.get(k) or {}).get('value', '')
    return {'thumb': ii.get('thumburl'), 'page': ii.get('descriptionurl'), 'license': g('LicenseShortName'), 'artist': g('Artist'), 'nonfree': g('NonFree')}
titles = json.load(open(sys.argv[1]))
out = {}
for key, title in titles.items():
    t, img = page_image(title)
    info = file_info(img) if img else None
    out[key] = {'title': t, 'file': img, **(info or {})}
    ok = info and not info['nonfree'] and info['license']
    print(f"{'OK ' if ok else '-- '} {key:20} {t!s:35} {img!s:45} {info and info['license']}")
json.dump(out, open(sys.argv[2], 'w'), indent=1)
