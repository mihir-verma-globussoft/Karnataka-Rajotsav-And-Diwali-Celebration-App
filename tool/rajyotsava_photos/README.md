# Rajyotsava photos

Photos for film stars, Discover Karnataka items and the CSV places, all from
**Wikimedia Commons** under free licences (Creative Commons, public domain,
GODL-India). Non-free files and files not on Commons are skipped. Credits are
generated into `lib/features/rajyotsava/data/rajyotsava_photos.dart` and shown
on the in-app **Photo credits** screen, as the licences require.

Run from this folder with Python 3 (network needed; requests are slowed down
to respect Wikimedia's rate limits):

1. `python3 probe.py stars.json stars_out.json` and
   `python3 probe.py discover.json discover_out.json`: page photo of each
   Wikipedia article in the JSON (id -> article title), with licence.
2. `python3 fetch.py stars stars_out.json dl_stars` and
   `python3 fetch.py discover discover_out.json dl_discover`: download.
   `fetch.py` adds hand-picked Commons files for stars whose article has no
   free photo (Shankar Nag's bust, Darshan, Yash).
3. `python3 places2.py ../../docs/data/karnataka_famous_places_google_maps.csv places2_out.json`,
   then `python3 filter_places.py`, then `python3 fetch_places.py`.
4. Review a contact sheet of the downloads and delete wrong ones from
   `dl_*/` and `dl_*/_credits.json`.
5. `python3 gen.py ../..`: resizes into `assets/images/` (stars 360 px,
   Discover 640 px, places 240 px) and writes the Dart data file.

Manual review decisions (2026-11-03):
- Aarathi: the only Commons photo is the Tamil actress Aarathi, not the
  Kannada actress; no photo. Kalpana: no free photo.
- Places dropped after review: maps and locators (Gurmitkal, Shahapur Fort,
  Bahmani Tombs Ashtur), Sandur Hills (a flag), Siddaganga Matha (a drawing
  of Basavanna), Shivappa Nayaka Palace (a statue, not the palace).

Downloads (`dl_*`, `*_out.json`, `places_keep.json`) are not committed.
