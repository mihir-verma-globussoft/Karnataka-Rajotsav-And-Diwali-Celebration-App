import '../domain/models.dart';

/// Kannada patriotic and folk songs, and Karnataka's folk art forms.
const List<CultureEntry> songsAndArts = [
  // Songs
  CultureEntry(
    id: 'jaya_bharata',
    kind: CultureKind.song,
    title: 'Jaya Bharata Jananiya Tanujate',
    kannadaTitle: 'ಜಯ ಭಾರತ ಜನನಿಯ ತನುಜಾತೆ',
    credit: 'Poem by Kuvempu · State song of Karnataka',
    description:
        'Karnataka\'s official state song (Naada Geethe). It praises '
        'Karnataka as a daughter of Mother India and names its rivers, '
        'poets and saints.',
    searchQuery: 'Jaya Bharata Jananiya Tanujate Karnataka state song',
  ),
  CultureEntry(
    id: 'huttidare',
    kind: CultureKind.song,
    title: 'Huttidare Kannada Naadalli Huttabeku',
    kannadaTitle: 'ಹುಟ್ಟಿದರೆ ಕನ್ನಡ ನಾಡಲ್ಲಿ ಹುಟ್ಟಬೇಕು',
    credit: 'Sung by Dr. Rajkumar · Film Aakasmika (1993)',
    description:
        '"If I am born, I must be born in the Kannada land." One of the '
        'most loved Kannada songs, played at every Rajyotsava.',
    searchQuery: 'Huttidare Kannada Naadalli Huttabeku Dr Rajkumar',
  ),
  CultureEntry(
    id: 'hachchevu',
    kind: CultureKind.song,
    title: 'Hachchevu Kannadada Deepa',
    kannadaTitle: 'ಹಚ್ಚೇವು ಕನ್ನಡದ ದೀಪ',
    credit: 'Poem by D. S. Karki',
    description:
        '"Let us light the lamp of Kannada." A call to keep the language '
        'and its pride alive, sung at schools and celebrations.',
    searchQuery: 'Hachchevu Kannadada Deepa song',
  ),
  CultureEntry(
    id: 'baarisu',
    kind: CultureKind.song,
    title: 'Baarisu Kannada Dindimava',
    kannadaTitle: 'ಬಾರಿಸು ಕನ್ನಡ ಡಿಂಡಿಮವ',
    credit: 'Poem by Kuvempu',
    description:
        '"Beat the drum of Kannada." A rousing poem calling on Kannadigas '
        'to celebrate their land and language.',
    searchQuery: 'Baarisu Kannada Dindimava Kuvempu song',
  ),
  CultureEntry(
    id: 'elladaru_iru',
    kind: CultureKind.song,
    title: 'Elladaru Iru Entadaru Iru',
    kannadaTitle: 'ಎಲ್ಲಾದರು ಇರು ಎಂತಾದರು ಇರು',
    credit: 'Poem by Kuvempu',
    description:
        '"Wherever you are, however you are, forever remain a Kannadiga." '
        'Kuvempu\'s best-known lines on Kannada identity.',
    searchQuery: 'Elladaru Iru Entadaru Iru Kuvempu song',
  ),
  CultureEntry(
    id: 'jogada_siri',
    kind: CultureKind.song,
    title: 'Jogada Siri Belakinalli',
    kannadaTitle: 'ಜೋಗದ ಸಿರಿ ಬೆಳಕಿನಲ್ಲಿ',
    credit: 'Poem by K. S. Nissar Ahmed',
    description:
        'A celebration of Karnataka\'s beauty, from the light of Jog Falls '
        'to the song of the Tunga river.',
    searchQuery: 'Jogada Siri Belakinalli song',
  ),
  CultureEntry(
    id: 'veera_ramaniya',
    kind: CultureKind.song,
    title: 'Kannada Naadina Veera Ramaniya',
    kannadaTitle: 'ಕನ್ನಡ ನಾಡಿನ ವೀರ ರಮಣಿಯ',
    credit: 'Film Naagarahaavu (1972)',
    description:
        'Tells the story of Onake Obavva, who defended Chitradurga Fort '
        'with a wooden pestle.',
    searchQuery: 'Kannada Naadina Veera Ramaniya Naagarahaavu',
  ),
  CultureEntry(
    id: 'bhagyada_balegara',
    kind: CultureKind.song,
    title: 'Bhagyada Balegara',
    kannadaTitle: 'ಭಾಗ್ಯದ ಬಳೆಗಾರ',
    credit: 'Janapada (folk) song',
    description:
        'A much-loved folk song in which a young bride asks the bangle '
        'seller to carry news to her mother\'s home.',
    searchQuery: 'Bhagyada Balegara janapada song',
  ),
  CultureEntry(
    id: 'kolu_kolanna',
    kind: CultureKind.song,
    title: 'Kolu Kolanna Kole',
    kannadaTitle: 'ಕೋಲು ಕೋಲಣ್ಣ ಕೋಲೆ',
    credit: 'Janapada (folk) song',
    description:
        'A rhythmic folk song sung while dancing Kolata, the stick dance, '
        'at village festivals.',
    searchQuery: 'Kolu Kolanna Kole janapada song',
  ),
  // Folk arts
  CultureEntry(
    id: 'yakshagana_art',
    kind: CultureKind.art,
    title: 'Yakshagana',
    kannadaTitle: 'ಯಕ್ಷಗಾನ',
    credit: 'Coastal Karnataka',
    description:
        'Dance-drama with music, dialogue and grand costumes and headgear, '
        'telling stories from the epics, often through the night.',
    searchQuery: 'Yakshagana performance',
  ),
  CultureEntry(
    id: 'dollu_kunitha',
    kind: CultureKind.art,
    title: 'Dollu Kunitha',
    kannadaTitle: 'ಡೊಳ್ಳು ಕುಣಿತ',
    credit: 'Across Karnataka',
    description:
        'A powerful drum dance: performers beat large drums hung from their '
        'necks while leaping and moving in formation.',
    searchQuery: 'Dollu Kunitha drum dance Karnataka',
  ),
  CultureEntry(
    id: 'veeragase',
    kind: CultureKind.art,
    title: 'Veeragase',
    kannadaTitle: 'ವೀರಗಾಸೆ',
    credit: 'Across Karnataka',
    description:
        'A vigorous warrior dance based on the legend of Veerabhadra, '
        'performed with a sword and shield at festivals such as Dasara.',
    searchQuery: 'Veeragase dance Karnataka',
  ),
  CultureEntry(
    id: 'kamsale',
    kind: CultureKind.art,
    title: 'Kamsale',
    kannadaTitle: 'ಕಂಸಾಳೆ',
    credit: 'Mysuru and Chamarajanagar',
    description:
        'Devotees of Male Mahadeshwara dance in rhythm while clashing a '
        'pair of bronze cymbals called kamsale.',
    searchQuery: 'Kamsale dance Karnataka',
  ),
  CultureEntry(
    id: 'huli_vesha',
    kind: CultureKind.art,
    title: 'Huli Vesha',
    kannadaTitle: 'ಹುಲಿ ವೇಷ',
    credit: 'Udupi and Mangaluru',
    description:
        'The tiger dance: performers painted as tigers dance to drums '
        'through the streets during Dasara and Krishna Janmashtami.',
    searchQuery: 'Huli Vesha tiger dance Udupi',
  ),
  CultureEntry(
    id: 'bhoota_kola',
    kind: CultureKind.art,
    title: 'Bhoota Kola',
    kannadaTitle: 'ಭೂತ ಕೋಲ',
    credit: 'Tulu Nadu (coastal Karnataka)',
    description:
        'A sacred ritual performance honouring local guardian spirits, with '
        'elaborate make-up, costumes and drumming.',
    searchQuery: 'Bhoota Kola Tulu Nadu',
  ),
  CultureEntry(
    id: 'togalu_gombeyaata',
    kind: CultureKind.art,
    title: 'Togalu Gombeyaata',
    kannadaTitle: 'ತೊಗಲು ಗೊಂಬೆಯಾಟ',
    credit: 'Across Karnataka',
    description:
        'Shadow puppetry with colourful leather puppets, telling stories '
        'from the Ramayana and Mahabharata.',
    searchQuery: 'Togalu Gombeyaata leather puppetry',
  ),
  CultureEntry(
    id: 'pooja_kunitha',
    kind: CultureKind.art,
    title: 'Pooja Kunitha',
    kannadaTitle: 'ಪೂಜಾ ಕುಣಿತ',
    credit: 'Southern Karnataka',
    description:
        'Dancers balance a tall decorated wooden frame dedicated to a '
        'goddess on their heads while dancing.',
    searchQuery: 'Pooja Kunitha dance Karnataka',
  ),
  CultureEntry(
    id: 'gee_gee_pada',
    kind: CultureKind.art,
    title: 'Gee Gee Pada',
    kannadaTitle: 'ಗೀಗೀ ಪದ',
    credit: 'North Karnataka',
    description:
        'Folk ballads sung by a group with a lead singer, telling stories '
        'of heroes, history and everyday life.',
    searchQuery: 'Gee Gee Pada North Karnataka folk',
  ),
  CultureEntry(
    id: 'kolata',
    kind: CultureKind.art,
    title: 'Kolata',
    kannadaTitle: 'ಕೋಲಾಟ',
    credit: 'Across Karnataka',
    description:
        'A stick dance in which pairs of dancers strike short sticks in '
        'rhythm while moving in circles and patterns.',
    searchQuery: 'Kolata stick dance Karnataka',
  ),
];
