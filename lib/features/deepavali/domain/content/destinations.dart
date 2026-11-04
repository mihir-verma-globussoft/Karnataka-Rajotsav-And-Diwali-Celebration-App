/// Attribution for a bundled photo (Wikimedia Commons).
class PhotoCredit {
  const PhotoCredit({
    required this.asset,
    required this.altText,
    required this.fileTitle,
    required this.author,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
  });

  /// Bundled asset path.
  final String asset;

  /// Describes the picture for screen readers.
  final String altText;
  final String fileTitle;
  final String author;
  final String license;
  final String licenseUrl;
  final String sourceUrl;

  /// Photos supplied by the app team have no source page.
  bool get isSupplied => sourceUrl.isEmpty;

  /// "Photo: Author, CC BY-SA 4.0, via Wikimedia Commons", or just
  /// "Photo: Author" for photos supplied by the team.
  String get line => isSupplied
      ? 'Photo: $author'
      : 'Photo: $author, $license, via Wikimedia Commons';
}

/// A short fact with the reference it was taken from.
class DestinationFact {
  const DestinationFact({required this.text, required this.source});

  final String text;

  /// Human-readable reference, e.g. "Wikipedia: Hawa Mahal".
  final String source;
}

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.state,
    required this.tagline,
    required this.description,
    required this.facts,
    required this.bestTime,
    required this.photo,
  });

  final String id;
  final String name;
  final String state;
  final String tagline;
  final List<String> description;
  final List<DestinationFact> facts;
  final String bestTime;
  final PhotoCredit photo;
}

/// Looks a destination up by id; null if unknown.
Destination? destinationById(String id) {
  for (final d in destinations) {
    if (d.id == id) return d;
  }
  return null;
}

const String _cc = 'https://creativecommons.org/licenses/by-sa/4.0';

/// Credit line for photos the app team supplied.
const String _team = 'Globus Habba team';
const String _teamLicense = 'supplied by the app team';

/// Six cities, in gallery order. Every fact carries a source. Photos show
/// Diwali being celebrated in each city (Ayodhya shows the Ram Mandir).
const List<Destination> destinations = [
  Destination(
    id: 'varanasi',
    name: 'Varanasi',
    state: 'Uttar Pradesh',
    tagline: 'Dev Deepawali on the Ganga ghats.',
    description: [
      'On the banks of the Ganga, Varanasi lights its stepped ghats with '
          'rows of earthen lamps. The city is best known for Dev Deepawali, '
          'the festival of lights of the gods, held about fifteen days after '
          'Diwali on Kartika Purnima.',
      'Crowds fill the ghats, lamps and lights cover the buildings along '
          'the river, and boats packed with visitors drift past for the '
          'evening Ganga aarti, which makes it one of the most atmospheric '
          'places to see the festival.',
    ],
    facts: [
      DestinationFact(
        text:
            'Dev Deepawali, also called Deva-Deepavali, is celebrated on '
            'Kartika Purnima and follows Diwali by about 15 days.',
        source: 'Wikipedia: Kartika Purnima',
      ),
      DestinationFact(
        text:
            'Dashashwamedh Ghat, one of Varanasi’s main ghats, was built in '
            'its present form around 1735 under Peshwa Balaji Baji Rao.',
        source: 'Wikipedia: Dashashwamedh Ghat',
      ),
    ],
    bestTime: 'Dev Deepawali night, about two weeks after Diwali.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/varanasi-dev-deepawali.jpg',
      altText:
          'Aerial view at night of the Varanasi ghats during Dev Deepawali, '
          'with crowds, lit buildings and boats on the Ganga',
      fileTitle: 'varanasi-deepotsav.jpg',
      author: _team,
      license: _teamLicense,
      licenseUrl: '',
      sourceUrl: '',
    ),
  ),
  Destination(
    id: 'jaipur',
    name: 'Jaipur',
    state: 'Rajasthan',
    tagline: 'The Pink City lit up for the festival.',
    description: [
      'During Diwali week Jaipur’s old city is decorated with lights, and '
          'its bazaars fill with people shopping for sweets, jewellery and '
          'festive decorations.',
      'Landmarks glow after dark. The Hawa Mahal, outlined in strings of '
          'lights with lamps along its base, is one of the city’s most '
          'photographed Diwali sights.',
    ],
    facts: [
      DestinationFact(
        text:
            'The Hawa Mahal was built in 1799 by Maharaja Sawai Pratap '
            'Singh and designed by Lal Chand Ustad.',
        source: 'Wikipedia: Hawa Mahal',
      ),
      DestinationFact(
        text:
            'Its five-storey façade has 953 small windows called jharokhas, '
            'which let royal ladies watch street life and festivals unseen.',
        source: 'Wikipedia: Hawa Mahal',
      ),
    ],
    bestTime: 'Evenings during Diwali week.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/jaipur-hawa-mahal.jpg',
      altText:
          'The Hawa Mahal in Jaipur lit up with strings of lights against '
          'a dark blue night sky',
      fileTitle: 'Jaipur.png',
      author: _team,
      license: _teamLicense,
      licenseUrl: '',
      sourceUrl: '',
    ),
  ),
  Destination(
    id: 'ayodhya',
    name: 'Ayodhya',
    state: 'Uttar Pradesh',
    tagline: 'Ram Mandir and the lamps of Deepotsav.',
    description: [
      'Ayodhya, on the banks of the Sarayu, is the city tradition links '
          'with Rama, whose return many Hindus remember at Diwali. It is '
          'home to the Ram Mandir, a major pilgrimage site.',
      'On the eve of Diwali the riverfront ghats, including Ram Ki Paidi, '
          'are lit with lamps in a large public celebration known as '
          'Deepotsav.',
    ],
    facts: [
      DestinationFact(
        text:
            'The Ram Mandir is a Hindu temple complex in Ayodhya and one of '
            'the most visited Hindu temples in India.',
        source: 'Wikipedia: Ram Mandir',
      ),
      DestinationFact(
        text:
            'Diwali is connected to the day Rama is said to have returned to '
            'his kingdom in Ayodhya after defeating Ravana.',
        source: 'Wikipedia: Diwali',
      ),
      DestinationFact(
        text:
            'In 2023 a Diwali celebration in Ayodhya set a Guinness World '
            'Record for the largest display of oil lamps: 2,223,676, '
            'beating the previous record of 1,576,944.',
        source: 'Wikipedia: Ayodhya',
      ),
    ],
    bestTime: 'The eve of Diwali.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/ayodhya.jpg',
      altText: 'The Ram Mandir in Ayodhya decorated with flowers',
      fileTitle: 'Ram Mandir, Ayodhya.png',
      author: 'Narendra Modi',
      license: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Ram_Mandir,_Ayodhya.png',
    ),
  ),
  Destination(
    id: 'amritsar',
    name: 'Amritsar',
    state: 'Punjab',
    tagline: 'The Golden Temple on Bandi Chhor Divas.',
    description: [
      'For Sikhs, the Diwali season is also Bandi Chhor Divas, the Day of '
          'Liberation, which marks Guru Hargobind’s release from Gwalior '
          'Fort.',
      'In Amritsar the Golden Temple (Harmandir Sahib) is lit up, its '
          'sarovar reflects the lights, and devotees set earthen lamps along '
          'the water’s edge.',
    ],
    facts: [
      DestinationFact(
        text:
            'Bandi Chhor Divas means “Day of Liberation”. It was formally '
            'adopted into the Nanakshahi calendar in 2003.',
        source: 'Wikipedia: Bandi Chhor Divas',
      ),
      DestinationFact(
        text:
            'The pool at the Golden Temple was completed by Guru Ram Das in '
            '1577, and over 150,000 people visit every day.',
        source: 'Wikipedia: Golden Temple',
      ),
    ],
    bestTime: 'Bandi Chhor Divas, which usually falls with Diwali.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/amritsar.jpg',
      altText:
          'Earthen lamps burning beside the pool with the illuminated Golden '
          'Temple behind, during Diwali',
      fileTitle: 'Diwali Festival. Jpg.jpg',
      author: 'Aayush sharma 923',
      license: 'CC BY-SA 4.0',
      licenseUrl: _cc,
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Diwali_Festival._Jpg.jpg',
    ),
  ),
  Destination(
    id: 'kolkata',
    name: 'Kolkata',
    state: 'West Bengal',
    tagline: 'Goddess pandals and Kali Puja on Diwali night.',
    description: [
      'In Bengal the new-moon night of Diwali is devoted to Kali Puja. '
          'Kolkata’s neighbourhoods set up pandals with large clay idols of '
          'the goddess, and homes are lit with lamps and candles.',
      'The city’s pandal tradition is at its grandest for Durga Puja a few '
          'weeks earlier, with richly decorated idols like the one pictured. '
          'By Diwali the same lanes glow again for Kali Puja.',
    ],
    facts: [
      DestinationFact(
        text:
            'Kali Puja, also called Shyama Puja or Mahanisha Puja, is held '
            'on the new-moon day of the month of Ashwayuja or Kartika.',
        source: 'Wikipedia: Kali Puja',
      ),
      DestinationFact(
        text:
            'The festival is especially popular in Kolkata and other parts '
            'of West Bengal.',
        source: 'Wikipedia: Kali Puja',
      ),
      DestinationFact(
        text:
            'Durga Puja in Kolkata was inscribed on UNESCO’s list of '
            'Intangible Cultural Heritage of Humanity in 2021.',
        source: 'Wikipedia: Durga Puja',
      ),
    ],
    bestTime: 'The new-moon night of Diwali.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/kolkata-durga.jpg',
      altText:
          'A richly decorated idol of the goddess Durga with many arms on a '
          'green and silver pandal in Kolkata',
      fileTitle: 'kolkata.jpeg',
      author: _team,
      license: _teamLicense,
      licenseUrl: '',
      sourceUrl: '',
    ),
  ),
  Destination(
    id: 'mumbai',
    name: 'Mumbai',
    state: 'Maharashtra',
    tagline: 'Fireworks over the Gateway of India.',
    description: [
      'Mumbai celebrates Diwali with lights and fireworks. The Gateway of '
          'India on the waterfront is lit up in colour, homes and housing '
          'societies are decorated with lamps and rangoli, and many '
          'businesses perform Lakshmi Puja and open new account books.',
      'The city’s stock exchanges also hold a special one-hour session on '
          'Diwali evening.',
    ],
    facts: [
      DestinationFact(
        text:
            'Muhurat trading is a special trading session held on Diwali, '
            'usually in the evening, announced in advance by the exchanges.',
        source: 'Wikipedia: Muhurat trading',
      ),
      DestinationFact(
        text:
            'During Diwali, people illuminate their homes, temples and '
            'workplaces with diyas, candles and lanterns.',
        source: 'Wikipedia: Diwali',
      ),
    ],
    bestTime: 'Diwali evening.',
    photo: PhotoCredit(
      asset: 'assets/deepavali/images/destinations/mumbai-gateway.jpg',
      altText:
          'The Gateway of India in Mumbai lit in gold and pink with colourful '
          'fireworks bursting in the night sky above it',
      fileTitle: 'Mumbai.png',
      author: _team,
      license: _teamLicense,
      licenseUrl: '',
      sourceUrl: '',
    ),
  ),
];
