import '../domain/easter_eggs.dart';

/// The hidden Karnataka collectibles. Add new ones here; ids are saved with
/// discoveries, so never change or reuse an id. `photoKey` is
/// `<group>:<key>` into RajyotsavaPhotos (star, discover, place or egg).
/// Legendary cards with a cut-out subject (popOut) rise out of the frame.
/// The cut-outs were made with tool/rajyotsava_photos/cutout.swift; their
/// subjectTop comes from where the cut-out's visible pixels start. Hampi,
/// Mysuru Dasara and the Western Ghats have no clear single subject in
/// their photo, so they stay flat.
const List<Collectible> karnatakaCollectibles = [
  // Personalities
  Collectible(
    id: 'rajkumar',
    category: EggCategory.personality,
    rarity: EggRarity.legendary,
    title: 'Dr. Rajkumar',
    kannadaTitle: 'ಡಾ. ರಾಜ್‌ಕುಮಾರ್',
    tagline: 'Nata Saarvabhouma, the emperor of acting',
    history:
        'Born in 1929 as Muthuraj, he made his debut as a hero in Bedara '
        'Kannappa (1954) and went on to act in more than 200 Kannada films. '
        'He also sang many of his own songs and led the Gokak agitation for '
        'the primacy of Kannada in 1982.',
    facts: [
      'First film as hero: Bedara Kannappa (1954)',
      'Karnataka Ratna, 1992',
      'Dadasaheb Phalke Award, 1995',
      'National Award for playback singing for "Naadamaya" (1992)',
    ],
    importance:
        'Annavru is the face of Kannada cinema and a symbol of pride in the '
        'Kannada language.',
    kannadaDescription:
        'ಕನ್ನಡ ಚಿತ್ರರಂಗದ ಮೇರು ನಟ ಮತ್ತು ಗಾಯಕ, ಎಲ್ಲರ ಪ್ರೀತಿಯ ಅಣ್ಣಾವ್ರು.',
    englishDescription:
        'The towering actor and singer of Kannada cinema, beloved as '
        'Annavru.',
    photoKey: 'star:rajkumar',
    popOut: PopOut(
      asset: 'assets/images/popouts/rajkumar.png',
      subjectTop: 0.04,
    ),
  ),
  Collectible(
    id: 'sangolli_rayanna',
    category: EggCategory.personality,
    rarity: EggRarity.rare,
    title: 'Sangolli Rayanna',
    kannadaTitle: 'ಸಂಗೊಳ್ಳಿ ರಾಯಣ್ಣ',
    tagline: 'Warrior of Kittur',
    history:
        'Born in 1798 in Sangolli, Belagavi, Rayanna was an army chief of '
        'Kittur. After the fall of Kittur he kept fighting the British East '
        'India Company with a guerrilla army, until he was captured and '
        'hanged at Nandagad in 1831.',
    facts: [
      'Born 1798 in Sangolli village',
      'Fought alongside Rani Chennamma in 1824',
      'Hanged by the British on 26 January 1831',
    ],
    importance:
        'One of Karnataka\'s earliest freedom fighters, remembered in folk '
        'songs across north Karnataka.',
    kannadaDescription:
        'ಕಿತ್ತೂರಿನ ವೀರ ಸೇನಾನಿ, ಬ್ರಿಟಿಷರ ವಿರುದ್ಧ ಹೋರಾಡಿದ ಸ್ವಾತಂತ್ರ್ಯ ಯೋಧ.',
    englishDescription:
        'The brave commander of Kittur who fought the British for freedom.',
    photoKey: 'egg:sangolli_rayanna',
    // A tall statue photo: keep the top, so his head is not cut off.
    photoFocusY: -1,
  ),
  Collectible(
    id: 'kittur_chennamma',
    category: EggCategory.personality,
    rarity: EggRarity.legendary,
    title: 'Kittur Rani Chennamma',
    kannadaTitle: 'ಕಿತ್ತೂರು ರಾಣಿ ಚೆನ್ನಮ್ಮ',
    tagline: 'The queen who defied an empire',
    history:
        'When the British refused to recognise her adopted son as heir, the '
        'queen of Kittur led an armed revolt in 1824 and won a first battle '
        'against the East India Company. She was later captured and died in '
        'Bailhongal fort in 1829.',
    facts: [
      'Lived 1778–1829',
      'Victory over the British on 23 October 1824',
      'Kittur Utsav is held every October in her memory',
    ],
    importance:
        'She resisted British rule more than 30 years before 1857 and is a '
        'symbol of courage in Karnataka.',
    kannadaDescription:
        'ಬ್ರಿಟಿಷರ ವಿರುದ್ಧ ಸಶಸ್ತ್ರ ಹೋರಾಟ ನಡೆಸಿದ ಕಿತ್ತೂರಿನ ವೀರ ರಾಣಿ.',
    englishDescription:
        'The heroic queen of Kittur who took up arms against the British.',
    photoKey: 'discover:kittur_chennamma',
    popOut: PopOut(
      asset: 'assets/images/popouts/kittur_chennamma.png',
      subjectTop: 0.19,
    ),
  ),
  Collectible(
    id: 'kuvempu',
    category: EggCategory.personality,
    rarity: EggRarity.legendary,
    title: 'Kuvempu',
    kannadaTitle: 'ಕುವೆಂಪು',
    tagline: 'Rashtrakavi, voice of the state song',
    history:
        'K. V. Puttappa (1904–1994) wrote poetry, plays and novels that '
        'shaped modern Kannada literature. His epic Sri Ramayana Darshanam '
        'won the first Jnanpith Award for Kannada, and he wrote the state '
        'song "Jaya Bharata Jananiya Tanujate".',
    facts: [
      'Jnanpith Award, 1967',
      'Rashtrakavi (national poet), 1964',
      'Padma Vibhushan, 1988',
      'Karnataka Ratna, 1992',
    ],
    importance:
        'His call to be a "Vishwa Manava", a universal human, still guides '
        'Kannada thought.',
    kannadaDescription: 'ರಾಷ್ಟ್ರಕವಿ, ಜ್ಞಾನಪೀಠ ಪುರಸ್ಕೃತ, ನಾಡಗೀತೆಯ ರಚನಕಾರ.',
    englishDescription:
        'National poet, Jnanpith winner and author of the state song.',
    photoKey: 'discover:kuvempu',
    popOut: PopOut(asset: 'assets/images/popouts/kuvempu.png', subjectTop: 0.0),
  ),
  Collectible(
    id: 'visvesvaraya',
    category: EggCategory.personality,
    rarity: EggRarity.rare,
    title: 'Sir M. Visvesvaraya',
    kannadaTitle: 'ಸರ್ ಎಂ. ವಿಶ್ವೇಶ್ವರಯ್ಯ',
    tagline: 'The engineer who built modern Mysore',
    history:
        'A visionary engineer (1861–1962), he was chief engineer of the '
        'Krishna Raja Sagara dam and Diwan of Mysore from 1912 to 1918, '
        'when the state started a bank, a soap factory and engineering '
        'colleges.',
    facts: [
      'Diwan of Mysore, 1912–1918',
      'Bharat Ratna, 1955',
      'Engineers\' Day, 15 September, is his birthday',
    ],
    importance:
        'He showed how engineering and planning could lift a whole state.',
    kannadaDescription:
        'ಕೆಆರ್‌ಎಸ್ ಅಣೆಕಟ್ಟಿನ ರೂವಾರಿ, ಮೈಸೂರಿನ ದಿವಾನರು, ಭಾರತರತ್ನ.',
    englishDescription:
        'Architect of the KRS dam, Diwan of Mysore and Bharat Ratna.',
    photoKey: 'discover:visvesvaraya',
  ),
  Collectible(
    id: 'basavanna',
    category: EggCategory.personality,
    rarity: EggRarity.legendary,
    title: 'Basavanna',
    kannadaTitle: 'ಬಸವಣ್ಣ',
    tagline: 'Poet-philosopher of equality',
    history:
        'In the 12th century Basavanna, a minister in the court of the '
        'Kalachuri king Bijjala II, taught equality and the dignity of work '
        'through vachanas, short poems in simple Kannada, and set up the '
        'Anubhava Mantapa at Kalyana.',
    facts: [
      'Born in Basavana Bagewadi, Vijayapura',
      'Founded the Anubhava Mantapa, a forum open to all',
      'Taught "Kayakave Kailasa": work is worship',
    ],
    importance:
        'His vachanas made Kannada the language of a social revolution.',
    kannadaDescription: 'ಕಾಯಕವೇ ಕೈಲಾಸ ಎಂದು ಸಾರಿದ ಸಮಾನತೆಯ ಹರಿಕಾರ.',
    englishDescription:
        'The champion of equality who taught that work is worship.',
    photoKey: 'discover:basavanna',
    popOut: PopOut(
      asset: 'assets/images/popouts/basavanna.png',
      subjectTop: 0.12,
    ),
  ),
  // Places and monuments
  Collectible(
    id: 'hampi',
    category: EggCategory.place,
    rarity: EggRarity.legendary,
    title: 'Hampi',
    kannadaTitle: 'ಹಂಪಿ',
    tagline: 'Capital of the Vijayanagara Empire',
    history:
        'From the 14th to the 16th century Hampi was the capital of the '
        'Vijayanagara Empire, one of the richest cities in the world. It was '
        'sacked after the Battle of Talikota in 1565, leaving temples and '
        'palaces among giant boulders.',
    facts: [
      'UNESCO World Heritage Site since 1986',
      'The stone chariot of the Vittala Temple',
      'The Virupaksha Temple is still in worship',
    ],
    importance: 'Hampi is the grandest reminder of Karnataka\'s golden age.',
    kannadaDescription: 'ವಿಜಯನಗರ ಸಾಮ್ರಾಜ್ಯದ ವೈಭವದ ರಾಜಧಾನಿ, ವಿಶ್ವ ಪರಂಪರೆಯ ತಾಣ.',
    englishDescription:
        'The glorious capital of Vijayanagara, a World Heritage Site.',
    photoKey: 'discover:hampi',
  ),
  Collectible(
    id: 'mysore_palace',
    category: EggCategory.place,
    rarity: EggRarity.rare,
    title: 'Mysore Palace',
    kannadaTitle: 'ಮೈಸೂರು ಅರಮನೆ',
    tagline: 'Royal home of the Wadiyars',
    history:
        'The old wooden palace burned down in 1897. The present palace, '
        'designed by Henry Irwin in the Indo-Saracenic style, was completed '
        'in 1912 for the Wadiyar kings of Mysore.',
    facts: [
      'Completed in 1912',
      'Lit with nearly a lakh of bulbs on festival evenings',
      'Heart of the Mysuru Dasara celebrations',
    ],
    importance:
        'One of India\'s most visited monuments and a symbol of Mysuru.',
    kannadaDescription: 'ಒಡೆಯರ ರಾಜವೈಭವವನ್ನು ಸಾರುವ ಮೈಸೂರಿನ ಭವ್ಯ ಅರಮನೆ.',
    englishDescription:
        'The magnificent palace that tells of the Wadiyars\' royal splendour.',
    photoKey: 'discover:mysuru_palace',
  ),
  Collectible(
    id: 'gol_gumbaz',
    category: EggCategory.place,
    rarity: EggRarity.rare,
    title: 'Gol Gumbaz',
    kannadaTitle: 'ಗೋಲ ಗುಮ್ಮಟ',
    tagline: 'The dome that whispers back',
    history:
        'The mausoleum of Mohammed Adil Shah of Bijapur was completed in '
        '1656. Its huge dome has a whispering gallery where even a soft '
        'sound is heard on the other side and echoes many times.',
    facts: [
      'Completed in 1656',
      'One of the largest domes in the world',
      'In Vijayapura (Bijapur)',
    ],
    importance: 'A masterpiece of Deccan architecture from the Adil Shahi era.',
    kannadaDescription: 'ಪಿಸುಮಾತನ್ನೂ ಪ್ರತಿಧ್ವನಿಸುವ ವಿಜಯಪುರದ ಬೃಹತ್ ಗುಮ್ಮಟ.',
    englishDescription: 'Vijayapura\'s giant dome that echoes even a whisper.',
    photoKey: 'discover:gol_gumbaz',
  ),
  Collectible(
    id: 'belur',
    category: EggCategory.place,
    rarity: EggRarity.rare,
    title: 'Belur Chennakeshava Temple',
    kannadaTitle: 'ಬೇಲೂರು ಚೆನ್ನಕೇಶವ ದೇವಾಲಯ',
    tagline: 'Hoysala art carved in stone',
    history:
        'The Hoysala king Vishnuvardhana built the temple in 1117, '
        'reportedly to mark his victory over the Cholas at Talakadu. Every '
        'surface is carved, from friezes of elephants to the graceful '
        'madanika bracket figures.',
    facts: [
      'Built in 1117 by Vishnuvardhana',
      'Famous for its madanika (celestial dancer) figures',
      'UNESCO World Heritage Site since 2023',
    ],
    importance: 'It shows the peak of Hoysala craftsmanship in soapstone.',
    kannadaDescription: 'ಮದನಿಕೆಯರ ಶಿಲ್ಪಗಳಿಂದ ಪ್ರಸಿದ್ಧವಾದ ಹೊಯ್ಸಳರ ಕಲಾ ದೇಗುಲ.',
    englishDescription:
        'The Hoysala temple famous for its madanika sculptures.',
    photoKey: 'discover:belur_halebidu',
  ),
  Collectible(
    id: 'halebidu',
    category: EggCategory.place,
    rarity: EggRarity.rare,
    title: 'Halebidu',
    kannadaTitle: 'ಹಳೇಬೀಡು',
    tagline: 'The old Hoysala capital',
    history:
        'Once called Dorasamudra, Halebidu was the Hoysala capital. Its '
        'Hoysaleswara Temple, begun around 1121, is covered with thousands '
        'of carvings of gods, animals and scenes from the epics.',
    facts: [
      'Hoysala capital, then called Dorasamudra',
      'Hoysaleswara Temple begun around 1121',
      'UNESCO World Heritage Site since 2023',
    ],
    importance: 'With Belur, it is the finest example of Hoysala architecture.',
    kannadaDescription: 'ಹೊಯ್ಸಳರ ರಾಜಧಾನಿ ದ್ವಾರಸಮುದ್ರ, ಶಿಲ್ಪಕಲೆಯ ಸಿರಿ.',
    englishDescription: 'Dorasamudra, the Hoysala capital, rich in sculpture.',
    photoKey: 'egg:halebidu',
  ),
  Collectible(
    id: 'badami_caves',
    category: EggCategory.place,
    rarity: EggRarity.rare,
    title: 'Badami Caves',
    kannadaTitle: 'ಬಾದಾಮಿ ಗುಹೆಗಳು',
    tagline: 'Temples cut into red sandstone',
    history:
        'Badami, once Vatapi, was the capital of the early Chalukyas. In the '
        '6th century four cave temples, three Hindu and one Jain, were '
        'carved into the red sandstone cliffs above Agastya Lake.',
    facts: [
      'Capital of the early Chalukyas',
      'Cave 3 has an inscription dated 578 CE',
      'Four caves: three Hindu, one Jain',
    ],
    importance: 'Some of the earliest rock-cut temples of the Deccan.',
    kannadaDescription: 'ಚಾಲುಕ್ಯರ ರಾಜಧಾನಿಯ ಕೆಂಪು ಬಂಡೆಯಲ್ಲಿ ಕೊರೆದ ಗುಹಾಲಯಗಳು.',
    englishDescription:
        'Cave temples carved into the red rock of the Chalukya capital.',
    photoKey: 'egg:badami_caves',
  ),
  // Culture
  Collectible(
    id: 'mysuru_dasara',
    category: EggCategory.culture,
    rarity: EggRarity.legendary,
    title: 'Mysuru Dasara',
    kannadaTitle: 'ಮೈಸೂರು ದಸರಾ',
    tagline: 'Nada Habba, the festival of the state',
    history:
        'Celebrated by the Wadiyars since 1610, the ten-day festival honours '
        'goddess Chamundeshwari\'s victory over Mahishasura. It ends on '
        'Vijayadashami with the Jamboo Savari, when an elephant carries the '
        'golden howdah through Mysuru.',
    facts: [
      'Celebrated since 1610',
      'The golden howdah weighs about 750 kg',
      'Ends with the Jamboo Savari on Vijayadashami',
    ],
    importance:
        'It is Karnataka\'s state festival and its grandest celebration.',
    kannadaDescription: 'ನಾಡಹಬ್ಬ ದಸರಾ, ಜಂಬೂ ಸವಾರಿಯ ವೈಭವದ ಉತ್ಸವ.',
    englishDescription:
        'The state festival, crowned by the splendid Jamboo Savari.',
    photoKey: 'discover:mysuru_dasara',
  ),
  Collectible(
    id: 'yakshagana',
    category: EggCategory.culture,
    rarity: EggRarity.rare,
    title: 'Yakshagana',
    kannadaTitle: 'ಯಕ್ಷಗಾನ',
    tagline: 'Dance-drama of the coast',
    history:
        'Yakshagana combines dance, music, dialogue and dazzling costumes to '
        'tell stories from the Ramayana and Mahabharata, traditionally '
        'performed through the night in coastal and Malnad Karnataka.',
    facts: [
      'Music by bhagavata, chande and maddale',
      'Shows often run from night until dawn',
      'Huge, glittering headgear called kirita',
    ],
    importance:
        'A living theatre tradition that keeps the epics alive in Kannada.',
    kannadaDescription: 'ಕರಾವಳಿಯ ರಾತ್ರಿಯಿಡೀ ನಡೆಯುವ ಗಂಡುಕಲೆ ಯಕ್ಷಗಾನ.',
    englishDescription:
        'The coast\'s all-night theatre art of dance and music.',
    photoKey: 'discover:yakshagana',
  ),
  Collectible(
    id: 'dollu_kunitha',
    category: EggCategory.culture,
    rarity: EggRarity.rare,
    title: 'Dollu Kunitha',
    kannadaTitle: 'ಡೊಳ್ಳು ಕುಣಿತ',
    tagline: 'Thunder of the drums',
    history:
        'Performed mainly by men of the Kuruba community in honour of '
        'Beereshwara, dancers beat large drums hung from their necks while '
        'leaping and moving in powerful formations.',
    facts: [
      'Big drums called dollu hang from the neck',
      'Performed at village festivals and processions',
      'Often seen in the Mysuru Dasara procession',
    ],
    importance: 'Its energy is a sound of celebration across Karnataka.',
    kannadaDescription: 'ಡೊಳ್ಳಿನ ಸದ್ದಿಗೆ ಹೆಜ್ಜೆ ಹಾಕುವ ಶಕ್ತಿಯುತ ಜಾನಪದ ನೃತ್ಯ.',
    englishDescription: 'A powerful folk dance to the beat of big drums.',
    photoKey: 'egg:dollu_kunitha',
  ),
  Collectible(
    id: 'kambala',
    category: EggCategory.culture,
    rarity: EggRarity.rare,
    title: 'Kambala',
    kannadaTitle: 'ಕಂಬಳ',
    tagline: 'Buffalo race in the paddy fields',
    history:
        'In Dakshina Kannada and Udupi, pairs of buffaloes driven by a '
        'farmer race along waterlogged paddy-field tracks. The season runs '
        'from November to March.',
    facts: [
      'Held from November to March',
      'Run on wet paddy-field tracks',
      'A tradition of Tulu Nadu',
    ],
    importance: 'It celebrates the farmers and harvest of coastal Karnataka.',
    kannadaDescription: 'ಕರಾವಳಿಯ ಗದ್ದೆಗಳಲ್ಲಿ ನಡೆಯುವ ಕೋಣಗಳ ಓಟದ ಸ್ಪರ್ಧೆ.',
    englishDescription:
        'The buffalo race held in the paddy fields of the coast.',
    photoKey: 'discover:kambala',
  ),
  Collectible(
    id: 'bhoota_kola',
    category: EggCategory.culture,
    rarity: EggRarity.rare,
    title: 'Bhoota Kola',
    kannadaTitle: 'ಭೂತ ಕೋಲ',
    tagline: 'Night of the guardian spirits',
    history:
        'In Tulu Nadu, local guardian spirits (daivas) are honoured in a '
        'sacred night-long ritual of drumming, chanting and dance, with the '
        'performer in elaborate make-up and costume.',
    facts: [
      'A ritual of Tulu Nadu, coastal Karnataka',
      'The performer is believed to embody the daiva',
      'The film Kantara (2022) brought it worldwide attention',
    ],
    importance:
        'A deeply rooted faith that binds coastal communities together.',
    kannadaDescription: 'ತುಳುನಾಡಿನ ದೈವಾರಾಧನೆಯ ಪವಿತ್ರ ಆಚರಣೆ ಭೂತ ಕೋಲ.',
    englishDescription: 'The sacred spirit-worship ritual of Tulu Nadu.',
    photoKey: 'egg:bhoota_kola',
  ),
  Collectible(
    id: 'mysore_silk',
    category: EggCategory.culture,
    rarity: EggRarity.rare,
    title: 'Mysore Silk',
    kannadaTitle: 'ಮೈಸೂರು ರೇಷ್ಮೆ',
    tagline: 'Pure silk, real gold zari',
    history:
        'Krishnaraja Wadiyar IV set up a silk weaving factory in Mysuru in '
        '1912 with looms from Switzerland. Mysore silk sarees are woven '
        'from pure mulberry silk with gold zari.',
    facts: [
      'Royal silk factory started in 1912',
      'Has a Geographical Indication (GI) tag',
      'Karnataka produces most of India\'s mulberry silk',
    ],
    importance: 'A world-famous craft and the pride of Karnataka\'s weavers.',
    kannadaDescription: 'ಚಿನ್ನದ ಜರಿಯ ಶುದ್ಧ ರೇಷ್ಮೆಯ ಮೈಸೂರು ಸೀರೆಗಳು.',
    englishDescription: 'Pure silk sarees of Mysuru with gold zari.',
    photoKey: 'discover:mysore_silk',
  ),
  // Nature
  Collectible(
    id: 'jog_falls',
    category: EggCategory.nature,
    rarity: EggRarity.rare,
    title: 'Jog Falls',
    kannadaTitle: 'ಜೋಗ ಜಲಪಾತ',
    tagline: 'Four streams, one mighty fall',
    history:
        'The Sharavathi river plunges about 253 metres in four streams '
        'named Raja, Rani, Roarer and Rocket. The falls are fullest in the '
        'monsoon.',
    facts: [
      'About 253 m high',
      'Streams: Raja, Rani, Roarer and Rocket',
      'Best seen from July to September',
    ],
    importance:
        'One of India\'s highest plunge waterfalls and a Karnataka icon.',
    kannadaDescription: 'ಶರಾವತಿ ನದಿಯ ರಾಜ, ರಾಣಿ, ರೋರರ್, ರಾಕೆಟ್ ಧಾರೆಗಳ ಜಲಪಾತ.',
    englishDescription:
        'The Sharavathi\'s four-stream waterfall: Raja, Rani, Roarer and '
        'Rocket.',
    photoKey: 'discover:jog_falls',
  ),
  Collectible(
    id: 'western_ghats',
    category: EggCategory.nature,
    rarity: EggRarity.legendary,
    title: 'Western Ghats',
    kannadaTitle: 'ಪಶ್ಚಿಮ ಘಟ್ಟಗಳು',
    tagline: 'A biodiversity hotspot',
    history:
        'The mountain range running along Karnataka\'s west is one of the '
        'richest places for wildlife on Earth. Its rainforests feed rivers '
        'such as the Kaveri, Tunga and Bhadra.',
    facts: [
      'UNESCO World Heritage Site since 2012',
      'Home to tigers, elephants and king cobras',
      'Source of the Kaveri at Talakaveri',
    ],
    importance: 'Its forests give Karnataka its rivers, rain and coffee.',
    kannadaDescription:
        'ಕರ್ನಾಟಕಕ್ಕೆ ನದಿ, ಮಳೆ ಮತ್ತು ಜೀವವೈವಿಧ್ಯ ನೀಡುವ ಸಹ್ಯಾದ್ರಿ.',
    englishDescription:
        'The Sahyadri that gives Karnataka its rivers, rain and wildlife.',
    photoKey: 'egg:western_ghats',
  ),
  Collectible(
    id: 'nandi_hills',
    category: EggCategory.nature,
    rarity: EggRarity.rare,
    title: 'Nandi Hills',
    kannadaTitle: 'ನಂದಿ ಬೆಟ್ಟ',
    tagline: 'Sunrise above the clouds',
    history:
        'About 60 km from Bengaluru, this hill rises to about 1,478 m. Tipu '
        'Sultan used it as a summer retreat, and rivers such as the '
        'Arkavathi and Dakshina Pinakini begin on its slopes.',
    facts: [
      'About 1,478 m high',
      'Tipu Sultan\'s summer retreat',
      'Famous for sunrises above the clouds',
    ],
    importance:
        'Bengaluru\'s favourite escape and the birthplace of several rivers.',
    kannadaDescription: 'ಮೋಡಗಳ ಮೇಲಿನ ಸೂರ್ಯೋದಯಕ್ಕೆ ಹೆಸರಾದ ನಂದಿ ಬೆಟ್ಟ.',
    englishDescription: 'Nandi Hills, famous for sunrise above the clouds.',
    photoKey: 'place:chikkaballapur|Nandi Hills',
  ),
  Collectible(
    id: 'kudremukh',
    category: EggCategory.nature,
    rarity: EggRarity.rare,
    title: 'Kudremukh',
    kannadaTitle: 'ಕುದುರೆಮುಖ',
    tagline: 'The horse-faced peak',
    history:
        'Named for its horse-face shape, Kudremukh peak rises to about '
        '1,894 m in Chikkamagaluru district. Its national park protects '
        'shola forests and grasslands where the Tunga, Bhadra and Netravati '
        'rivers begin.',
    facts: [
      'Peak about 1,894 m high',
      'Kudremukh National Park, shola grasslands',
      'Source of the Tunga, Bhadra and Netravati',
    ],
    importance:
        'A green treasure of the Western Ghats and a trekkers\' favourite.',
    kannadaDescription: 'ಕುದುರೆಯ ಮುಖದಂತಿರುವ ಸಹ್ಯಾದ್ರಿಯ ಹಸಿರು ಶಿಖರ.',
    englishDescription: 'The green Sahyadri peak shaped like a horse\'s face.',
    photoKey: 'egg:kudremukh',
  ),
];

/// Clues to the ways of finding a collectible, one per secret: shaking,
/// and each hidden tap (see SecretTap). Vague on purpose.
const List<EggHint> karnatakaEggHints = [
  EggHint(
    kannada: 'ಅಲ್ಲಾಡಿಸಿ!',
    english: 'Shake your phone on any Rajyotsava screen.',
  ),
  EggHint(
    kannada: 'ನಮ್ಮ ಬಾವುಟ',
    english: 'Our flag likes attention. Tap it again and again.',
  ),
  EggHint(
    kannada: 'ಮೊದಲ ಅಕ್ಷರಗಳು',
    english: 'The first letters you learn hide a secret.',
  ),
  EggHint(
    kannada: 'ಅಣ್ಣಾವ್ರು',
    english: 'Say hello to Annavru, the Natasarvabhouma, again and again.',
  ),
  EggHint(kannada: 'ಗೆದ್ದವರಿಗೆ', english: 'Finish a quiz and tap your trophy.'),
  EggHint(
    kannada: 'ನಿಮ್ಮ ಸುತ್ತಮುತ್ತ',
    english: 'Something waits near you. Keep tapping.',
  ),
  EggHint(
    kannada: 'ಜಿಲ್ಲೆಯ ಗುರುತು',
    english: 'Every district has a symbol. Tap it.',
  ),
  EggHint(
    kannada: 'ತಾಳ್ಮೆ',
    english: "Songs reward patience. Hold, don't tap.",
  ),
];
