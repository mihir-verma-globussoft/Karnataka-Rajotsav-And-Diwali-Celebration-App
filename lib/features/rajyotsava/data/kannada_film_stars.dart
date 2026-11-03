import '../domain/models.dart';

/// Famous Kannada film stars and some of their best-known films.
const List<FilmStar> kannadaFilmStars = [
  // Actors
  FilmStar(
    id: 'rajkumar',
    name: 'Dr. Rajkumar',
    kannadaName: 'ಡಾ. ರಾಜ್‌ಕುಮಾರ್',
    role: StarRole.actor,
    knownAs: 'Annavru · Nata Saarvabhouma',
    about:
        'The greatest icon of Kannada cinema: more than 200 films and a '
        'beloved playback singer. Dadasaheb Phalke Award, 1995.',
    films: [
      Film('Bedara Kannappa', 1954),
      Film('Kasturi Nivasa', 1971),
      Film('Bangarada Manushya', 1972),
      Film('Mayura', 1975),
      Film('Babruvahana', 1977),
      Film('Jeevana Chaitra', 1992),
    ],
  ),
  FilmStar(
    id: 'vishnuvardhan',
    name: 'Dr. Vishnuvardhan',
    kannadaName: 'ಡಾ. ವಿಷ್ಣುವರ್ಧನ್',
    role: StarRole.actor,
    knownAs: 'Sahasa Simha',
    about:
        'Became a star with his first lead role in Naagarahaavu and acted '
        'in more than 200 films over four decades.',
    films: [
      Film('Naagarahaavu', 1972),
      Film('Bandhana', 1984),
      Film('Suprabhatha', 1988),
      Film('Muthina Haara', 1990),
      Film('Yajamana', 2000),
      Film('Aptharakshaka', 2010),
    ],
  ),
  FilmStar(
    id: 'ambareesh',
    name: 'Ambareesh',
    kannadaName: 'ಅಂಬರೀಷ್',
    role: StarRole.actor,
    knownAs: 'Rebel Star',
    about:
        'Known for his rebel roles, he began as Jaleela in Naagarahaavu and '
        'later served as a Union minister.',
    films: [
      Film('Naagarahaavu', 1972),
      Film('Antha', 1981),
      Film('Chakravyuha', 1983),
      Film('Elu Suttina Kote', 1988),
      Film('Mannina Doni', 1992),
    ],
  ),
  FilmStar(
    id: 'shankar_nag',
    name: 'Shankar Nag',
    kannadaName: 'ಶಂಕರ್ ನಾಗ್',
    role: StarRole.actor,
    knownAs: 'Karate King',
    about:
        'Actor and visionary director whose TV series Malgudi Days is loved '
        'across India.',
    films: [
      Film('Ondanondu Kaladalli', 1978),
      Film('Minchina Ota', 1980),
      Film('Auto Raja', 1980),
      Film('Geetha', 1981),
      Film('Accident', 1984),
    ],
  ),
  FilmStar(
    id: 'anant_nag',
    name: 'Anant Nag',
    kannadaName: 'ಅನಂತ್ ನಾಗ್',
    role: StarRole.actor,
    knownAs: '',
    about:
        'One of the most versatile actors in Indian cinema, in Kannada, '
        'Hindi and other languages; Shankar Nag\'s elder brother.',
    films: [
      Film('Bayalu Daari', 1976),
      Film('Chandanada Gombe', 1979),
      Film('Ganeshana Maduve', 1990),
      Film('Gaalipata', 2008),
      Film('Godhi Banna Sadharana Mykattu', 2016),
    ],
  ),
  FilmStar(
    id: 'shivarajkumar',
    name: 'Shiva Rajkumar',
    kannadaName: 'ಶಿವರಾಜ್‌ಕುಮಾರ್',
    role: StarRole.actor,
    knownAs: 'Hat-trick Hero · Century Star',
    about:
        'His first three films were all hits, earning him the title '
        'Hat-trick Hero; Om became a cult classic.',
    films: [
      Film('Anand', 1986),
      Film('Om', 1995),
      Film('Jogi', 2005),
      Film('Mufti', 2017),
      Film('Tagaru', 2018),
    ],
  ),
  FilmStar(
    id: 'puneeth_rajkumar',
    name: 'Puneeth Rajkumar',
    kannadaName: 'ಪುನೀತ್ ರಾಜ್‌ಕುಮಾರ್',
    role: StarRole.actor,
    knownAs: 'Power Star · Appu',
    about:
        'Won a National Award as a child for Bettada Hoovu and became one '
        'of Kannada\'s most loved stars; Karnataka Ratna, 2021.',
    films: [
      Film('Bettada Hoovu', 1985),
      Film('Appu', 2002),
      Film('Milana', 2007),
      Film('Jackie', 2010),
      Film('Raajakumara', 2017),
    ],
  ),
  FilmStar(
    id: 'upendra',
    name: 'Upendra',
    kannadaName: 'ಉಪೇಂದ್ರ',
    role: StarRole.actor,
    knownAs: 'Real Star',
    about:
        'Actor and director famous for bold, unconventional films; he '
        'directed Om before starring in his own films.',
    films: [
      Film('Om', 1995),
      Film('A', 1998),
      Film('Upendra', 1999),
      Film('Super', 2010),
      Film('UI', 2024),
    ],
  ),
  FilmStar(
    id: 'sudeep',
    name: 'Sudeep',
    kannadaName: 'ಕಿಚ್ಚ ಸುದೀಪ್',
    role: StarRole.actor,
    knownAs: 'Kiccha · Abhinaya Chakravarthy',
    about:
        'Actor, director and host of Bigg Boss Kannada, also known across '
        'India for Eega.',
    films: [
      Film('Huchcha', 2001),
      Film('Kiccha', 2003),
      Film('Swathi Muthu', 2003),
      Film('Eega', 2012),
      Film('Vikrant Rona', 2022),
    ],
  ),
  FilmStar(
    id: 'darshan',
    name: 'Darshan',
    kannadaName: 'ದರ್ಶನ್',
    role: StarRole.actor,
    knownAs: 'Challenging Star',
    about: 'Mass-action star whose first lead role was Majestic.',
    films: [
      Film('Majestic', 2002),
      Film('Kariya', 2003),
      Film('Saarathi', 2011),
      Film('Yajamana', 2019),
      Film('Kaatera', 2023),
    ],
  ),
  FilmStar(
    id: 'yash',
    name: 'Yash',
    kannadaName: 'ಯಶ್',
    role: StarRole.actor,
    knownAs: 'Rocking Star',
    about:
        'The K.G.F films took Kannada cinema to audiences across India and '
        'the world.',
    films: [
      Film('Moggina Manasu', 2008),
      Film('Googly', 2013),
      Film('Mr. and Mrs. Ramachari', 2014),
      Film('K.G.F: Chapter 1', 2018),
      Film('K.G.F: Chapter 2', 2022),
    ],
  ),
  FilmStar(
    id: 'rishab_shetty',
    name: 'Rishab Shetty',
    kannadaName: 'ರಿಷಬ್ ಶೆಟ್ಟಿ',
    role: StarRole.actor,
    knownAs: '',
    about:
        'Wrote, directed and starred in Kantara, which won him the National '
        'Award for Best Actor.',
    films: [
      Film('Kirik Party', 2016),
      Film('Bell Bottom', 2019),
      Film('Kantara', 2022),
    ],
  ),
  FilmStar(
    id: 'rakshit_shetty',
    name: 'Rakshit Shetty',
    kannadaName: 'ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ',
    role: StarRole.actor,
    knownAs: '',
    about:
        'Actor, writer and director; 777 Charlie won the National Award for '
        'Best Kannada Film.',
    films: [
      Film('Simple Agi Ondh Love Story', 2013),
      Film('Ulidavaru Kandanthe', 2014),
      Film('Kirik Party', 2016),
      Film('777 Charlie', 2022),
      Film('Sapta Saagaradaache Ello', 2023),
    ],
  ),
  // Actresses
  FilmStar(
    id: 'saroja_devi',
    name: 'B. Saroja Devi',
    kannadaName: 'ಬಿ. ಸರೋಜಾ ದೇವಿ',
    role: StarRole.actress,
    knownAs: 'Abhinaya Saraswathi',
    about:
        'A legend of South Indian cinema who starred in Kannada, Tamil, '
        'Telugu and Hindi films.',
    films: [
      Film('Mahakavi Kalidasa', 1955),
      Film('Kittur Chennamma', 1961),
      Film('Babruvahana', 1977),
    ],
  ),
  FilmStar(
    id: 'kalpana',
    name: 'Kalpana',
    kannadaName: 'ಕಲ್ಪನಾ',
    role: StarRole.actress,
    knownAs: 'Minugu Taare',
    about:
        'One of the finest actresses of the 1960s and 70s, remembered for '
        'Sharapanjara.',
    films: [
      Film('Bellimoda', 1967),
      Film('Gejje Pooje', 1970),
      Film('Sharapanjara', 1971),
    ],
  ),
  FilmStar(
    id: 'bharathi',
    name: 'Bharathi Vishnuvardhan',
    kannadaName: 'ಭಾರತಿ ವಿಷ್ಣುವರ್ಧನ್',
    role: StarRole.actress,
    knownAs: '',
    about:
        'A leading star of the 1960s and 70s who acted opposite Dr. '
        'Rajkumar in many hits.',
    films: [
      Film('Mayor Muthanna', 1969),
      Film('Sri Krishnadevaraya', 1970),
      Film('Bangarada Manushya', 1972),
    ],
  ),
  FilmStar(
    id: 'aarathi',
    name: 'Aarathi',
    kannadaName: 'ಆರತಿ',
    role: StarRole.actress,
    knownAs: '',
    about: 'Celebrated heroine of director Puttanna Kanagal\'s classics.',
    films: [
      Film('Naagarahaavu', 1972),
      Film('Shubhamangala', 1975),
      Film('Ranganayaki', 1981),
    ],
  ),
  FilmStar(
    id: 'ramya',
    name: 'Ramya',
    kannadaName: 'ರಮ್ಯಾ',
    role: StarRole.actress,
    knownAs: '',
    about: 'A top star of the 2000s who debuted opposite Puneeth Rajkumar.',
    films: [
      Film('Abhi', 2003),
      Film('Excuse Me', 2003),
      Film('Sanju Weds Geetha', 2011),
    ],
  ),
];
