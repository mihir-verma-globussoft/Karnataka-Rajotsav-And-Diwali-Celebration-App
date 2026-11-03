import '../domain/models.dart';
import 'kannada_film_stars.dart';
import 'karnataka_districts.dart';
import 'karnataka_places.dart';
import 'songs_and_arts.dart';

/// All Rajyotsava content, bundled in the app so it works offline.
/// To add a quiz question, word or place, add an entry to the lists below.
const RajyotsavaContent bundledRajyotsavaContent = RajyotsavaContent(
  history: _history,
  facts: _facts,
  wishes: _wishes,
  quiz: _quiz,
  vowels: _vowels,
  consonants: _consonants,
  phrases: _phrases,
  numbers: _numbers,
  discover: _discover,
  districts: karnatakaDistricts,
  culture: songsAndArts,
  places: karnatakaPlaces,
  filmStars: kannadaFilmStars,
);

const _history = [
  HistoryEvent(
    year: '1956',
    text:
        'On 1 November, Kannada-speaking regions of Bombay, Hyderabad and '
        'Madras states and Coorg were united with Mysore State under the '
        'States Reorganisation Act.',
  ),
  HistoryEvent(
    year: '1973',
    text:
        'On 1 November, Mysore State was renamed Karnataka, under Chief '
        'Minister D. Devaraj Urs.',
  ),
  HistoryEvent(
    year: '2008',
    text: 'Kannada was declared a classical language of India.',
  ),
  HistoryEvent(
    year: 'Today',
    text:
        'Every 1 November the red and yellow Kannada flag is hoisted across '
        'the state, and the Karnataka Rajyotsava Award honours people who '
        'have served the state.',
  ),
];

const _facts = [
  'The Kannada alphabet has 49 letters: 13 vowels, 2 yogavahas and 34 '
      'consonants.',
  'Kannada writers have received eight Jnanpith Awards, India\'s highest '
      'literary honour.',
  'The Halmidi inscription, from around 450 CE, is one of the earliest '
      'known inscriptions in Kannada.',
  'Karnataka grows about 70% of India\'s coffee, mostly in Kodagu, '
      'Chikkamagaluru and Hassan.',
  'Mysuru Dasara has been celebrated for more than 400 years.',
  'Karnataka is home to the largest population of wild Asian elephants in '
      'India.',
  'The Kannada film industry is fondly called Sandalwood.',
  'Bengaluru is often called the Silicon Valley of India.',
];

const _wishes = [
  RajyotsavaWish(
    kannada: 'ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು!',
    english: 'Heartfelt wishes on Kannada Rajyotsava!',
  ),
  RajyotsavaWish(
    kannada: 'ಸಿರಿಗನ್ನಡಂ ಗೆಲ್ಗೆ, ಸಿರಿಗನ್ನಡಂ ಬಾಳ್ಗೆ!',
    english: 'Victory to glorious Kannada, long live glorious Kannada!',
  ),
  RajyotsavaWish(
    kannada: 'ಎಲ್ಲಾದರು ಇರು, ಎಂತಾದರು ಇರು, ಎಂದೆಂದಿಗು ನೀ ಕನ್ನಡವಾಗಿರು.',
    english:
        'Wherever you are, however you are, forever remain a Kannadiga. '
        '(Kuvempu)',
  ),
  RajyotsavaWish(
    kannada: 'ಬಾರಿಸು ಕನ್ನಡ ಡಿಂಡಿಮವ!',
    english: 'Beat the drum of Kannada! (Kuvempu)',
  ),
];

const _quiz = [
  QuizQuestion(
    id: 'date',
    difficulty: QuizDifficulty.easy,
    question: 'On which date is Karnataka Rajyotsava celebrated?',
    options: ['26 January', '1 November', '15 August', '2 October'],
    answerIndex: 1,
    explanation: 'Karnataka Rajyotsava is celebrated every year on 1 November.',
  ),
  QuizQuestion(
    id: 'formed',
    difficulty: QuizDifficulty.easy,
    question: 'In which year was the state, then called Mysore State, formed?',
    options: ['1947', '1950', '1956', '1973'],
    answerIndex: 2,
    explanation:
        'Kannada-speaking regions were united on 1 November 1956 under the '
        'States Reorganisation Act.',
  ),
  QuizQuestion(
    id: 'renamed',
    difficulty: QuizDifficulty.medium,
    question: 'In which year was Mysore State renamed Karnataka?',
    options: ['1973', '1956', '1980', '1964'],
    answerIndex: 0,
    explanation: 'The state was renamed Karnataka on 1 November 1973.',
  ),
  QuizQuestion(
    id: 'renamed_cm',
    difficulty: QuizDifficulty.hard,
    question:
        'Who was the Chief Minister when the state was renamed Karnataka?',
    options: [
      'S. Nijalingappa',
      'Ramakrishna Hegde',
      'D. Devaraj Urs',
      'Veerendra Patil',
    ],
    answerIndex: 2,
    explanation: 'D. Devaraj Urs was Chief Minister in 1973.',
  ),
  QuizQuestion(
    id: 'capital',
    difficulty: QuizDifficulty.easy,
    question: 'What is the capital of Karnataka?',
    options: ['Mysuru', 'Hubballi', 'Mangaluru', 'Bengaluru'],
    answerIndex: 3,
    explanation: 'Bengaluru is the capital and largest city of Karnataka.',
  ),
  QuizQuestion(
    id: 'flag',
    difficulty: QuizDifficulty.easy,
    question: 'What are the colours of the Kannada flag?',
    options: [
      'Red and green',
      'Yellow and red',
      'Saffron and white',
      'Blue and yellow',
    ],
    answerIndex: 1,
    explanation: 'The Kannada flag is yellow on top and red below.',
  ),
  QuizQuestion(
    id: 'kempegowda',
    difficulty: QuizDifficulty.medium,
    question: 'Who founded the city of Bengaluru in 1537?',
    options: ['Kempe Gowda', 'Tipu Sultan', 'Krishnadevaraya', 'Hyder Ali'],
    answerIndex: 0,
    explanation: 'Kempe Gowda, a chieftain under the Vijayanagara Empire, founded Bengaluru.',
  ),
  QuizQuestion(
    id: 'animal',
    difficulty: QuizDifficulty.easy,
    question: 'Which is the state animal of Karnataka?',
    options: ['Tiger', 'Peacock', 'Asian elephant', 'Gaur'],
    answerIndex: 2,
    explanation: 'The Asian elephant is the state animal of Karnataka.',
  ),
  QuizQuestion(
    id: 'bird',
    difficulty: QuizDifficulty.easy,
    question: 'Which is the state bird of Karnataka?',
    options: [
      'Indian peafowl',
      'Indian roller',
      'Great hornbill',
      'Kingfisher',
    ],
    answerIndex: 1,
    explanation: 'The Indian roller, called Neelakanta, is the state bird.',
  ),
  QuizQuestion(
    id: 'tree',
    difficulty: QuizDifficulty.easy,
    question: 'Which is the state tree of Karnataka?',
    options: ['Banyan', 'Teak', 'Neem', 'Sandalwood'],
    answerIndex: 3,
    explanation: 'Sandalwood is the state tree; Karnataka is famous for it.',
  ),
  QuizQuestion(
    id: 'flower',
    difficulty: QuizDifficulty.easy,
    question: 'Which is the state flower of Karnataka?',
    options: ['Lotus', 'Jasmine', 'Rose', 'Marigold'],
    answerIndex: 0,
    explanation: 'The lotus is the state flower of Karnataka.',
  ),
  QuizQuestion(
    id: 'jnanpith',
    difficulty: QuizDifficulty.medium,
    question: 'Who was the first Kannada writer to receive the Jnanpith Award?',
    options: ['D. R. Bendre', 'Shivaram Karanth', 'Girish Karnad', 'Kuvempu'],
    answerIndex: 3,
    explanation: 'Kuvempu received the Jnanpith Award in 1967 for Sri Ramayana Darshanam.',
  ),
  QuizQuestion(
    id: 'anthem',
    difficulty: QuizDifficulty.medium,
    question: 'Who wrote the state song "Jaya Bharata Jananiya Tanujate"?',
    options: [
      'Kuvempu',
      'Masti Venkatesha Iyengar',
      'Basavanna',
      'Purandara Dasa',
    ],
    answerIndex: 0,
    explanation: 'The state song was written by Kuvempu.',
  ),
  QuizQuestion(
    id: 'hampi',
    difficulty: QuizDifficulty.medium,
    question: 'Hampi was the capital of which empire?',
    options: ['Chalukya', 'Hoysala', 'Vijayanagara', 'Rashtrakuta'],
    answerIndex: 2,
    explanation: 'Hampi was the capital of the Vijayanagara Empire.',
  ),
  QuizQuestion(
    id: 'gommateshwara',
    difficulty: QuizDifficulty.medium,
    question: 'The giant monolithic statue at Shravanabelagola depicts whom?',
    options: ['Buddha', 'Gommateshwara (Bahubali)', 'Mahavira', 'Basavanna'],
    answerIndex: 1,
    explanation: 'The 57-foot statue of Gommateshwara, also called Bahubali, was carved around 983 CE.',
  ),
  QuizQuestion(
    id: 'jamboo_savari',
    difficulty: QuizDifficulty.medium,
    question: 'What is the famous elephant procession of Mysuru Dasara called?',
    options: ['Karaga', 'Kambala', 'Jamboo Savari', 'Hampi Utsav'],
    answerIndex: 2,
    explanation:
        'Jamboo Savari takes place on Vijayadashami, the last day of Dasara.',
  ),
  QuizQuestion(
    id: 'jog',
    difficulty: QuizDifficulty.medium,
    question: 'Jog Falls is formed by which river?',
    options: ['Kaveri', 'Sharavathi', 'Tungabhadra', 'Krishna'],
    answerIndex: 1,
    explanation:
        'Jog Falls is formed by the Sharavathi river in Shivamogga district.',
  ),
  QuizQuestion(
    id: 'classical',
    difficulty: QuizDifficulty.hard,
    question: 'In which year was Kannada declared a classical language?',
    options: ['2004', '2014', '1999', '2008'],
    answerIndex: 3,
    explanation: 'Kannada received classical language status in 2008.',
  ),
  QuizQuestion(
    id: 'peak',
    difficulty: QuizDifficulty.medium,
    question: 'Which is the highest peak in Karnataka?',
    options: ['Mullayanagiri', 'Kudremukh', 'Kodachadri', 'Nandi Hills'],
    answerIndex: 0,
    explanation:
        'Mullayanagiri in Chikkamagaluru district is the highest peak.',
  ),
  QuizQuestion(
    id: 'gol_gumbaz',
    difficulty: QuizDifficulty.medium,
    question: 'In which city is the Gol Gumbaz?',
    options: ['Kalaburagi', 'Bidar', 'Vijayapura', 'Belagavi'],
    answerIndex: 2,
    explanation:
        'The Gol Gumbaz, famous for its whispering gallery, is in Vijayapura.',
  ),
  QuizQuestion(
    id: 'coorg',
    difficulty: QuizDifficulty.medium,
    question: 'Which district is often called the "Scotland of India"?',
    options: ['Udupi', 'Kodagu', 'Hassan', 'Uttara Kannada'],
    answerIndex: 1,
    explanation:
        'Kodagu (Coorg) is known for its misty hills and coffee estates.',
  ),
  QuizQuestion(
    id: 'yakshagana',
    difficulty: QuizDifficulty.easy,
    question: 'What is Yakshagana?',
    options: [
      'A sweet dish',
      'A boat race',
      'A temple',
      'A traditional dance-drama',
    ],
    answerIndex: 3,
    explanation: 'Yakshagana is a dance-drama from coastal Karnataka, often performed through the night.',
  ),
  QuizQuestion(
    id: 'rajkumar',
    difficulty: QuizDifficulty.easy,
    question: 'Which Kannada film legend is fondly called "Annavru"?',
    options: ['Dr. Rajkumar', 'Vishnuvardhan', 'Ambareesh', 'Shankar Nag'],
    answerIndex: 0,
    explanation: 'Dr. Rajkumar, who acted in more than 200 films, is fondly called Annavru.',
  ),
  QuizQuestion(
    id: 'kittur',
    difficulty: QuizDifficulty.medium,
    question: 'Which queen fought the British East India Company in 1824?',
    options: [
      'Rani Abbakka',
      'Kittur Rani Chennamma',
      'Keladi Chennamma',
      'Onake Obavva',
    ],
    answerIndex: 1,
    explanation: 'Kittur Rani Chennamma led an armed revolt against the British in 1824.',
  ),
  QuizQuestion(
    id: 'halmidi',
    difficulty: QuizDifficulty.hard,
    question: 'What is the Halmidi inscription known for?',
    options: [
      'The oldest coffee estate',
      'Being one of the earliest Kannada inscriptions',
      'The first Kannada film',
      'Founding Mysuru Palace',
    ],
    answerIndex: 1,
    explanation: 'Dated to around 450 CE, it is one of the earliest known Kannada inscriptions.',
  ),
  QuizQuestion(
    id: 'language',
    difficulty: QuizDifficulty.easy,
    question: 'What is the official language of Karnataka?',
    options: ['Tamil', 'Kannada', 'Telugu', 'Marathi'],
    answerIndex: 1,
    explanation: 'Kannada is the official language of Karnataka.',
  ),
  QuizQuestion(
    id: 'dasara_city',
    difficulty: QuizDifficulty.easy,
    question: 'Which city is famous for its grand Dasara celebrations?',
    options: ['Hubballi', 'Mangaluru', 'Mysuru', 'Belagavi'],
    answerIndex: 2,
    explanation: 'Mysuru Dasara has been celebrated for more than 400 years.',
  ),
  QuizQuestion(
    id: 'mysore_pak',
    difficulty: QuizDifficulty.easy,
    question: 'Which sweet is named after a city in Karnataka?',
    options: ['Rasgulla', 'Mysore Pak', 'Jalebi', 'Peda'],
    answerIndex: 1,
    explanation: 'Mysore Pak is said to have been first made in the Mysuru Palace kitchens.',
  ),
  QuizQuestion(
    id: 'sandalwood',
    difficulty: QuizDifficulty.easy,
    question: 'What is the Kannada film industry fondly called?',
    options: ['Bollywood', 'Tollywood', 'Sandalwood', 'Mollywood'],
    answerIndex: 2,
    explanation: 'Kannada cinema is called Sandalwood, after the state tree.',
  ),
  QuizQuestion(
    id: 'kaveri',
    difficulty: QuizDifficulty.easy,
    question: 'Which river begins at Talakaveri in Kodagu?',
    options: ['Kaveri', 'Krishna', 'Tungabhadra', 'Sharavathi'],
    answerIndex: 0,
    explanation:
        'The Kaveri begins at Talakaveri and flows through southern Karnataka.',
  ),
  QuizQuestion(
    id: 'silicon_valley',
    difficulty: QuizDifficulty.easy,
    question: 'Which city is often called the Silicon Valley of India?',
    options: ['Mysuru', 'Bengaluru', 'Mangaluru', 'Kalaburagi'],
    answerIndex: 1,
    explanation: 'Bengaluru is India\'s leading IT and start-up city.',
  ),
  QuizQuestion(
    id: 'coffee',
    difficulty: QuizDifficulty.easy,
    question: 'Karnataka grows most of India\'s…',
    options: ['Tea', 'Cotton', 'Coffee', 'Rubber'],
    answerIndex: 2,
    explanation: 'Karnataka grows about 70% of India\'s coffee, mostly in Kodagu, Chikkamagaluru and Hassan.',
  ),
  QuizQuestion(
    id: 'kambala_easy',
    difficulty: QuizDifficulty.easy,
    question: 'What is Kambala?',
    options: ['A buffalo race', 'A temple festival', 'A sweet', 'A boat race'],
    answerIndex: 0,
    explanation: 'Kambala is a buffalo race held in the paddy fields of coastal Karnataka.',
  ),
  QuizQuestion(
    id: 'namaskara',
    difficulty: QuizDifficulty.easy,
    question: 'What does "Namaskara" mean?',
    options: ['Thank you', 'Goodbye', 'Hello', 'Sorry'],
    answerIndex: 2,
    explanation: 'Namaskara (ನಮಸ್ಕಾರ) is the Kannada greeting for hello.',
  ),
  QuizQuestion(
    id: 'jamboo_elephant',
    difficulty: QuizDifficulty.easy,
    question: 'Which animal leads the Jamboo Savari procession in Mysuru?',
    options: ['Horse', 'Camel', 'Elephant', 'Bull'],
    answerIndex: 2,
    explanation: 'Decorated elephants lead the Jamboo Savari on Vijayadashami.',
  ),
  QuizQuestion(
    id: 'hoysala',
    difficulty: QuizDifficulty.medium,
    question: 'Which dynasty built the temples at Belur and Halebidu?',
    options: ['Hoysala', 'Chola', 'Kadamba', 'Ganga'],
    answerIndex: 0,
    explanation: 'The Hoysalas built them in the 12th century.',
  ),
  QuizQuestion(
    id: 'badami',
    difficulty: QuizDifficulty.medium,
    question: 'Badami was the capital of which dynasty?',
    options: ['Rashtrakutas', 'Chalukyas', 'Hoysalas', 'Wadiyars'],
    answerIndex: 1,
    explanation: 'Badami (Vatapi) was the capital of the early Chalukyas.',
  ),
  QuizQuestion(
    id: 'pattadakal_district',
    difficulty: QuizDifficulty.medium,
    question: 'In which district is Pattadakal, a UNESCO World Heritage Site?',
    options: ['Bagalkote', 'Hassan', 'Koppal', 'Ballari'],
    answerIndex: 0,
    explanation: 'Pattadakal, Badami and Aihole are all in Bagalkote district.',
  ),
  QuizQuestion(
    id: 'vijayanagara_founders',
    difficulty: QuizDifficulty.medium,
    question: 'Who founded the Vijayanagara Empire?',
    options: [
      'Harihara and Bukka',
      'Krishnadevaraya',
      'Pulakeshin II',
      'Vishnuvardhana',
    ],
    answerIndex: 0,
    explanation: 'Harihara I and Bukka Raya I founded it in the 14th century.',
  ),
  QuizQuestion(
    id: 'krishnadevaraya',
    difficulty: QuizDifficulty.medium,
    question: 'Which Vijayanagara emperor is celebrated for his rule in the early 16th century?',
    options: ['Krishnadevaraya', 'Tipu Sultan', 'Kempe Gowda', 'Pulakeshin II'],
    answerIndex: 0,
    explanation: 'Krishnadevaraya ruled from 1509 to 1529 and was a great patron of poets.',
  ),
  QuizQuestion(
    id: 'wadiyar',
    difficulty: QuizDifficulty.medium,
    question: 'Mysuru Palace is the home of which royal family?',
    options: ['Wadiyars', 'Hoysalas', 'Nayakas', 'Adil Shahis'],
    answerIndex: 0,
    explanation: 'The Wadiyars ruled the Kingdom of Mysore.',
  ),
  QuizQuestion(
    id: 'krs_river',
    difficulty: QuizDifficulty.medium,
    question: 'The Krishna Raja Sagara (KRS) dam is built across which river?',
    options: ['Krishna', 'Kaveri', 'Tungabhadra', 'Kabini'],
    answerIndex: 1,
    explanation: 'KRS dam is on the Kaveri, near Mysuru.',
  ),
  QuizQuestion(
    id: 'krs_engineer',
    difficulty: QuizDifficulty.medium,
    question: 'Which engineer is known for the KRS dam?',
    options: [
      'Sir M. Visvesvaraya',
      'Kempe Gowda',
      'C. V. Raman',
      'Satish Dhawan',
    ],
    answerIndex: 0,
    explanation: 'Sir M. Visvesvaraya was its chief engineer; Engineers\' Day is held on his birthday.',
  ),
  QuizQuestion(
    id: 'channapatna',
    difficulty: QuizDifficulty.medium,
    question: 'Which town is famous for lacquered wooden toys?',
    options: ['Ilkal', 'Channapatna', 'Udupi', 'Bidar'],
    answerIndex: 1,
    explanation: 'Channapatna is known as the town of toys.',
  ),
  QuizQuestion(
    id: 'bidriware',
    difficulty: QuizDifficulty.medium,
    question: 'Bidriware, metalwork inlaid with silver, comes from which city?',
    options: ['Bidar', 'Belagavi', 'Dharwad', 'Hassan'],
    answerIndex: 0,
    explanation: 'Bidriware is named after Bidar.',
  ),
  QuizQuestion(
    id: 'bandipur',
    difficulty: QuizDifficulty.medium,
    question: 'In which district is Bandipur National Park?',
    options: ['Kodagu', 'Chamarajanagar', 'Shivamogga', 'Uttara Kannada'],
    answerIndex: 1,
    explanation: 'Bandipur Tiger Reserve is in Chamarajanagar district.',
  ),
  QuizQuestion(
    id: 'basavanna_vachanas',
    difficulty: QuizDifficulty.medium,
    question: 'Which 12th-century reformer taught through vachanas?',
    options: ['Purandara Dasa', 'Basavanna', 'Kanaka Dasa', 'Pampa'],
    answerIndex: 1,
    explanation: 'Basavanna\'s vachanas are short poems in simple Kannada.',
  ),
  QuizQuestion(
    id: 'gulbarga',
    difficulty: QuizDifficulty.medium,
    question: 'Which city was earlier called Gulbarga?',
    options: ['Kalaburagi', 'Belagavi', 'Vijayapura', 'Ballari'],
    answerIndex: 0,
    explanation: 'Gulbarga was renamed Kalaburagi in 2014.',
  ),
  QuizQuestion(
    id: 'bijapur',
    difficulty: QuizDifficulty.medium,
    question: 'Which city was earlier called Bijapur?',
    options: ['Bidar', 'Vijayapura', 'Raichur', 'Bagalkote'],
    answerIndex: 1,
    explanation: 'Bijapur was renamed Vijayapura in 2014.',
  ),
  QuizQuestion(
    id: 'rayanna',
    difficulty: QuizDifficulty.hard,
    question: 'Which freedom fighter, a lieutenant of Kittur Chennamma, was hanged by the British in 1831?',
    options: ['Sangolli Rayanna', 'Tipu Sultan', 'Onake Obavva', 'Hyder Ali'],
    answerIndex: 0,
    explanation: 'Sangolli Rayanna continued the fight after 1824 and was hanged in 1831.',
  ),
  QuizQuestion(
    id: 'kavirajamarga',
    difficulty: QuizDifficulty.hard,
    question: 'Kavirajamarga, the earliest surviving Kannada literary work, is linked to the court of which king?',
    options: [
      'Amoghavarsha I',
      'Krishnadevaraya',
      'Pulakeshin II',
      'Vishnuvardhana',
    ],
    answerIndex: 0,
    explanation: 'It was written in the 9th century at the court of the Rashtrakuta king Amoghavarsha I.',
  ),
  QuizQuestion(
    id: 'pampa',
    difficulty: QuizDifficulty.hard,
    question: 'Which epic did Pampa, the "Adikavi" of Kannada, write?',
    options: [
      'Vikramarjuna Vijaya',
      'Gadayuddha',
      'Sri Ramayana Darshanam',
      'Karnata Bharata Kathamanjari',
    ],
    answerIndex: 0,
    explanation:
        'Pampa wrote Vikramarjuna Vijaya (Pampa Bharata) in the 10th century.',
  ),
  QuizQuestion(
    id: 'karnad',
    difficulty: QuizDifficulty.hard,
    question: 'Which Kannada playwright received the Jnanpith Award in 1998?',
    options: [
      'Girish Karnad',
      'U. R. Ananthamurthy',
      'Chandrashekhara Kambara',
      'Shivaram Karanth',
    ],
    answerIndex: 0,
    explanation:
        'Girish Karnad, author of Tughlaq and Hayavadana, received it in 1998.',
  ),
  QuizQuestion(
    id: 'jnanpith_count',
    difficulty: QuizDifficulty.hard,
    question: 'How many Jnanpith Awards have Kannada writers received?',
    options: ['Five', 'Six', 'Eight', 'Ten'],
    answerIndex: 2,
    explanation: 'Eight: Kuvempu, Bendre, Karanth, Masti, Gokak, Ananthamurthy, Karnad and Kambar.',
  ),
  QuizQuestion(
    id: 'bendre',
    difficulty: QuizDifficulty.hard,
    question: 'Which Kannada poet wrote under the pen name Ambikatanayadatta?',
    options: [
      'D. R. Bendre',
      'Kuvempu',
      'G. S. Shivarudrappa',
      'K. S. Narasimhaswamy',
    ],
    answerIndex: 0,
    explanation: 'D. R. Bendre won the Jnanpith Award in 1973.',
  ),
  QuizQuestion(
    id: 'ekikarana',
    difficulty: QuizDifficulty.hard,
    question: 'What was the Karnataka Ekikarana movement for?',
    options: [
      'Uniting Kannada-speaking regions into one state',
      'Building dams on the Kaveri',
      'Independence from Britain',
      'Founding universities',
    ],
    answerIndex: 0,
    explanation:
        'It led to the formation of the unified state on 1 November 1956.',
  ),
  QuizQuestion(
    id: 'nijalingappa',
    difficulty: QuizDifficulty.hard,
    question: 'Who became Chief Minister of the unified Mysore State on 1 November 1956?',
    options: [
      'S. Nijalingappa',
      'D. Devaraj Urs',
      'Kengal Hanumanthaiah',
      'B. D. Jatti',
    ],
    answerIndex: 0,
    explanation:
        'S. Nijalingappa was the first Chief Minister of the unified state.',
  ),
  QuizQuestion(
    id: 'vijayanagara_district',
    difficulty: QuizDifficulty.hard,
    question: 'In which year was Vijayanagara district carved out of Ballari?',
    options: ['2016', '2019', '2021', '2023'],
    answerIndex: 2,
    explanation: 'Vijayanagara became Karnataka\'s 31st district in 2021.',
  ),
  QuizQuestion(
    id: 'samskara',
    difficulty: QuizDifficulty.hard,
    question: 'Which Kannada film won the National Award for Best Feature Film for 1970?',
    options: ['Samskara', 'Bedara Kannappa', 'Naagarahaavu', 'Sharapanjara'],
    answerIndex: 0,
    explanation: 'Samskara, based on U. R. Ananthamurthy\'s novel, won the top national honour.',
  ),
  QuizQuestion(
    id: 'talikota',
    difficulty: QuizDifficulty.hard,
    question: 'The Battle of Talikota in 1565 led to the fall of which empire?',
    options: ['Hoysala', 'Vijayanagara', 'Chalukya', 'Mysore'],
    answerIndex: 1,
    explanation: 'Hampi was sacked after the battle.',
  ),
  QuizQuestion(
    id: 'srirangapatna',
    difficulty: QuizDifficulty.hard,
    question: 'Tipu Sultan died in 1799 defending which fort?',
    options: ['Chitradurga', 'Srirangapatna', 'Bidar', 'Devanahalli'],
    answerIndex: 1,
    explanation: 'He fell defending his capital, Srirangapatna.',
  ),
  QuizQuestion(
    id: 'purandara',
    difficulty: QuizDifficulty.hard,
    question: 'Which saint-composer is called the father of Carnatic music?',
    options: ['Kanaka Dasa', 'Purandara Dasa', 'Basavanna', 'Sarvajna'],
    answerIndex: 1,
    explanation:
        'Purandara Dasa composed songs with the signature "Purandara Vittala".',
  ),
  QuizQuestion(
    id: 'akka_mahadevi',
    difficulty: QuizDifficulty.hard,
    question: 'Akka Mahadevi addressed her vachanas to which deity?',
    options: [
      'Chennamallikarjuna',
      'Virupaksha',
      'Chamundeshwari',
      'Venkateshwara',
    ],
    answerIndex: 0,
    explanation: 'The 12th-century poet called her god Chennamallikarjuna.',
  ),
];

const _vowels = [
  KannadaLetter('ಅ', 'a'),
  KannadaLetter('ಆ', 'ā'),
  KannadaLetter('ಇ', 'i'),
  KannadaLetter('ಈ', 'ī'),
  KannadaLetter('ಉ', 'u'),
  KannadaLetter('ಊ', 'ū'),
  KannadaLetter('ಋ', 'ru'),
  KannadaLetter('ಎ', 'e'),
  KannadaLetter('ಏ', 'ē'),
  KannadaLetter('ಐ', 'ai'),
  KannadaLetter('ಒ', 'o'),
  KannadaLetter('ಓ', 'ō'),
  KannadaLetter('ಔ', 'au'),
  KannadaLetter('ಅಂ', 'am'),
  KannadaLetter('ಅಃ', 'ah'),
];

const _consonants = [
  KannadaLetter('ಕ', 'ka'),
  KannadaLetter('ಖ', 'kha'),
  KannadaLetter('ಗ', 'ga'),
  KannadaLetter('ಘ', 'gha'),
  KannadaLetter('ಙ', 'ṅa'),
  KannadaLetter('ಚ', 'cha'),
  KannadaLetter('ಛ', 'chha'),
  KannadaLetter('ಜ', 'ja'),
  KannadaLetter('ಝ', 'jha'),
  KannadaLetter('ಞ', 'ña'),
  KannadaLetter('ಟ', 'ṭa'),
  KannadaLetter('ಠ', 'ṭha'),
  KannadaLetter('ಡ', 'ḍa'),
  KannadaLetter('ಢ', 'ḍha'),
  KannadaLetter('ಣ', 'ṇa'),
  KannadaLetter('ತ', 'ta'),
  KannadaLetter('ಥ', 'tha'),
  KannadaLetter('ದ', 'da'),
  KannadaLetter('ಧ', 'dha'),
  KannadaLetter('ನ', 'na'),
  KannadaLetter('ಪ', 'pa'),
  KannadaLetter('ಫ', 'pha'),
  KannadaLetter('ಬ', 'ba'),
  KannadaLetter('ಭ', 'bha'),
  KannadaLetter('ಮ', 'ma'),
  KannadaLetter('ಯ', 'ya'),
  KannadaLetter('ರ', 'ra'),
  KannadaLetter('ಲ', 'la'),
  KannadaLetter('ವ', 'va'),
  KannadaLetter('ಶ', 'sha'),
  KannadaLetter('ಷ', 'ṣa'),
  KannadaLetter('ಸ', 'sa'),
  KannadaLetter('ಹ', 'ha'),
  KannadaLetter('ಳ', 'ḷa'),
];

const _phrases = [
  KannadaPhrase(
    kannada: 'ನಮಸ್ಕಾರ',
    pronunciation: 'Namaskāra',
    meaning: 'Hello',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ಹೇಗಿದ್ದೀರಾ?',
    pronunciation: 'Hēgiddīrā?',
    meaning: 'How are you?',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ನಾನು ಚೆನ್ನಾಗಿದ್ದೀನಿ',
    pronunciation: 'Nānu chennāgiddīni',
    meaning: 'I am fine',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ನಿಮ್ಮ ಹೆಸರೇನು?',
    pronunciation: 'Nimma hesarēnu?',
    meaning: 'What is your name?',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ನನ್ನ ಹೆಸರು …',
    pronunciation: 'Nanna hesaru …',
    meaning: 'My name is …',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ಧನ್ಯವಾದಗಳು',
    pronunciation: 'Dhanyavādagaḷu',
    meaning: 'Thank you',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ಹೋಗಿ ಬನ್ನಿ',
    pronunciation: 'Hōgi banni',
    meaning: 'Goodbye (literally "go and come back")',
    category: PhraseCategory.greetings,
  ),
  KannadaPhrase(
    kannada: 'ಹೌದು',
    pronunciation: 'Haudu',
    meaning: 'Yes',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಇಲ್ಲ',
    pronunciation: 'Illa',
    meaning: 'No',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಸರಿ',
    pronunciation: 'Sari',
    meaning: 'Okay',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಊಟ ಆಯ್ತಾ?',
    pronunciation: 'Ūṭa āytā?',
    meaning: 'Have you eaten?',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಎಷ್ಟು?',
    pronunciation: 'Eṣṭu?',
    meaning: 'How much?',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಎಲ್ಲಿ?',
    pronunciation: 'Elli?',
    meaning: 'Where?',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ನೀರು',
    pronunciation: 'Nīru',
    meaning: 'Water',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಗೊತ್ತಿಲ್ಲ',
    pronunciation: 'Gottilla',
    meaning: 'I don\'t know',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಸ್ವಲ್ಪ ಸ್ವಲ್ಪ ಕನ್ನಡ ಗೊತ್ತು',
    pronunciation: 'Swalpa swalpa Kannaḍa gottu',
    meaning: 'I know a little Kannada',
    category: PhraseCategory.everyday,
  ),
  KannadaPhrase(
    kannada: 'ಕನ್ನಡ ರಾಜ್ಯೋತ್ಸವದ ಶುಭಾಶಯಗಳು',
    pronunciation: 'Kannaḍa Rājyōtsavada shubhāshayagaḷu',
    meaning: 'Happy Kannada Rajyotsava',
    category: PhraseCategory.festival,
  ),
  KannadaPhrase(
    kannada: 'ಸಿರಿಗನ್ನಡಂ ಗೆಲ್ಗೆ',
    pronunciation: 'Sirigannaḍaṁ gelge',
    meaning: 'Victory to glorious Kannada',
    category: PhraseCategory.festival,
  ),
  KannadaPhrase(
    kannada: 'ಜೈ ಕರ್ನಾಟಕ ಮಾತೆ',
    pronunciation: 'Jai Karnāṭaka Māte',
    meaning: 'Hail Mother Karnataka',
    category: PhraseCategory.festival,
  ),
  KannadaPhrase(
    kannada: 'ಹಬ್ಬ',
    pronunciation: 'Habba',
    meaning: 'Festival',
    category: PhraseCategory.festival,
  ),
  KannadaPhrase(
    kannada: 'ಬಾವುಟ',
    pronunciation: 'Bāvuṭa',
    meaning: 'Flag',
    category: PhraseCategory.festival,
  ),
];

const _numbers = [
  KannadaNumber(value: 1, numeral: '೧', word: 'ಒಂದು', pronunciation: 'ondu'),
  KannadaNumber(value: 2, numeral: '೨', word: 'ಎರಡು', pronunciation: 'eraḍu'),
  KannadaNumber(value: 3, numeral: '೩', word: 'ಮೂರು', pronunciation: 'mūru'),
  KannadaNumber(value: 4, numeral: '೪', word: 'ನಾಲ್ಕು', pronunciation: 'nālku'),
  KannadaNumber(value: 5, numeral: '೫', word: 'ಐದು', pronunciation: 'aidu'),
  KannadaNumber(value: 6, numeral: '೬', word: 'ಆರು', pronunciation: 'āru'),
  KannadaNumber(value: 7, numeral: '೭', word: 'ಏಳು', pronunciation: 'ēḷu'),
  KannadaNumber(value: 8, numeral: '೮', word: 'ಎಂಟು', pronunciation: 'eṇṭu'),
  KannadaNumber(
    value: 9,
    numeral: '೯',
    word: 'ಒಂಬತ್ತು',
    pronunciation: 'ombattu',
  ),
  KannadaNumber(
    value: 10,
    numeral: '೧೦',
    word: 'ಹತ್ತು',
    pronunciation: 'hattu',
  ),
];

const _discover = [
  // Places
  DiscoverItem(
    id: 'hampi',
    name: 'Hampi',
    kannadaName: 'ಹಂಪಿ',
    category: DiscoverCategory.places,
    kind: DiscoverKind.monument,
    tagline: 'Ruins of the Vijayanagara capital',
    location: 'Vijayanagara district',
    description:
        'Hampi was the capital of the Vijayanagara Empire, one of the '
        'richest cities in the world in the 16th century. Its temples, '
        'markets and royal buildings are spread across a landscape of giant '
        'boulders on the banks of the Tungabhadra.',
    highlights: [
      'UNESCO World Heritage Site since 1986',
      'The stone chariot at the Vittala Temple',
      'The Virupaksha Temple is still in worship today',
    ],
    mapQuery: 'Hampi, Karnataka',
  ),
  DiscoverItem(
    id: 'mysuru_palace',
    name: 'Mysuru Palace',
    kannadaName: 'ಮೈಸೂರು ಅರಮನೆ',
    category: DiscoverCategory.places,
    kind: DiscoverKind.monument,
    tagline: 'Royal home of the Wadiyars',
    location: 'Mysuru',
    description:
        'The official residence of the Wadiyar dynasty, the rulers of Mysore '
        'kingdom. The present palace was completed in 1912 in the '
        'Indo-Saracenic style and is one of the most visited monuments in '
        'India.',
    highlights: [
      'Lit up with thousands of bulbs on festival evenings',
      'Centre of the Mysuru Dasara celebrations',
      'Golden howdah carried in the Jamboo Savari',
    ],
    mapQuery: 'Mysore Palace, Mysuru, Karnataka',
  ),
  DiscoverItem(
    id: 'jog_falls',
    name: 'Jog Falls',
    kannadaName: 'ಜೋಗ ಜಲಪಾತ',
    category: DiscoverCategory.places,
    kind: DiscoverKind.waterfall,
    tagline: 'One of India\'s highest plunge waterfalls',
    location: 'Shivamogga district',
    description:
        'The Sharavathi river drops about 253 metres in four streams, named '
        'Raja, Rani, Roarer and Rocket. The falls are at their fullest '
        'during the monsoon.',
    highlights: [
      'Formed by the Sharavathi river',
      'Four streams: Raja, Rani, Roarer and Rocket',
      'Best seen from July to September',
    ],
    mapQuery: 'Jog Falls, Shivamogga, Karnataka',
  ),
  DiscoverItem(
    id: 'gol_gumbaz',
    name: 'Gol Gumbaz',
    kannadaName: 'ಗೋಲ ಗುಮ್ಮಟ',
    category: DiscoverCategory.places,
    kind: DiscoverKind.monument,
    tagline: 'The dome with a whispering gallery',
    location: 'Vijayapura',
    description:
        'The mausoleum of Mohammed Adil Shah of the Adil Shahi dynasty, '
        'completed in 1656. Its huge dome has a whispering gallery where a '
        'soft sound is echoed many times.',
    highlights: [
      'Completed in 1656',
      'One of the largest domes in the world',
      'Whispers carry across the gallery',
    ],
    mapQuery: 'Gol Gumbaz, Vijayapura, Karnataka',
  ),
  DiscoverItem(
    id: 'shravanabelagola',
    name: 'Shravanabelagola',
    kannadaName: 'ಶ್ರವಣಬೆಳಗೊಳ',
    category: DiscoverCategory.places,
    kind: DiscoverKind.temple,
    tagline: 'Home of the Gommateshwara statue',
    location: 'Hassan district',
    description:
        'An important Jain pilgrimage centre. On the Vindhyagiri hill stands '
        'the 57-foot monolithic statue of Gommateshwara (Bahubali), carved '
        'around 983 CE.',
    highlights: [
      'One of the largest monolithic statues in the world',
      'Mahamastakabhisheka is held about every 12 years',
      'More than 600 steps lead to the top of the hill',
    ],
    mapQuery: 'Gommateshwara Statue, Shravanabelagola, Karnataka',
  ),
  DiscoverItem(
    id: 'belur_halebidu',
    name: 'Belur and Halebidu',
    kannadaName: 'ಬೇಲೂರು ಮತ್ತು ಹಳೇಬೀಡು',
    category: DiscoverCategory.places,
    kind: DiscoverKind.temple,
    tagline: 'Masterpieces of Hoysala carving',
    location: 'Hassan district',
    description:
        'The Chennakeshava Temple at Belur and the Hoysaleswara Temple at '
        'Halebidu are covered in intricate soapstone carvings of gods, '
        'dancers, animals and scenes from the epics.',
    highlights: [
      'Built by the Hoysala dynasty in the 12th century',
      'Part of the UNESCO site "Sacred Ensembles of the Hoysalas" (2023)',
    ],
    mapQuery: 'Chennakeshava Temple, Belur, Karnataka',
  ),
  DiscoverItem(
    id: 'kodagu',
    name: 'Kodagu (Coorg)',
    kannadaName: 'ಕೊಡಗು',
    category: DiscoverCategory.places,
    kind: DiscoverKind.nature,
    tagline: 'Misty hills and coffee estates',
    location: 'Western Ghats',
    description:
        'A hill district of forests, coffee and spice plantations, often '
        'called the Scotland of India. The Kaveri river begins at Talakaveri '
        'in Kodagu.',
    highlights: [
      'Source of the Kaveri river at Talakaveri',
      'One of India\'s main coffee-growing regions',
      'Abbey Falls and Dubare elephant camp',
    ],
    mapQuery: 'Madikeri, Kodagu, Karnataka',
  ),
  // Food
  DiscoverItem(
    id: 'mysore_pak',
    name: 'Mysore Pak',
    kannadaName: 'ಮೈಸೂರು ಪಾಕ್',
    category: DiscoverCategory.food,
    kind: DiscoverKind.sweet,
    tagline: 'The royal sweet from the palace kitchen',
    location: 'Mysuru',
    description:
        'A rich sweet made from gram flour, ghee and sugar. It is said to '
        'have been first made in the kitchens of Mysuru Palace for the '
        'Wadiyar kings.',
    highlights: [
      'Made with gram flour, ghee and sugar',
      'Comes soft and melt-in-the-mouth or firm and porous',
    ],
  ),
  DiscoverItem(
    id: 'bisi_bele_bath',
    name: 'Bisi Bele Bath',
    kannadaName: 'ಬಿಸಿ ಬೇಳೆ ಬಾತ್',
    category: DiscoverCategory.food,
    kind: DiscoverKind.dish,
    tagline: 'Hot lentil rice, Karnataka style',
    location: 'Across Karnataka',
    description:
        'Rice and toor dal cooked with vegetables, tamarind and a special '
        'spice powder. The name means "hot lentil rice". It is usually '
        'served with boondi or chips.',
    highlights: [
      'Name means "hot lentil rice"',
      'A favourite breakfast and lunch dish',
    ],
  ),
  DiscoverItem(
    id: 'ragi_mudde',
    name: 'Ragi Mudde',
    kannadaName: 'ರಾಗಿ ಮುದ್ದೆ',
    category: DiscoverCategory.food,
    kind: DiscoverKind.dish,
    tagline: 'Healthy finger-millet balls',
    location: 'Southern Karnataka',
    description:
        'Balls of cooked ragi (finger millet) flour, eaten with saaru or '
        'bassaru. It is filling and nutritious, and a staple in rural '
        'Karnataka.',
    highlights: [
      'Made from ragi, rich in calcium and fibre',
      'Eaten by swallowing small pieces dipped in saaru',
    ],
  ),
  DiscoverItem(
    id: 'benne_dose',
    name: 'Davanagere Benne Dose',
    kannadaName: 'ದಾವಣಗೆರೆ ಬೆಣ್ಣೆ ದೋಸೆ',
    category: DiscoverCategory.food,
    kind: DiscoverKind.dish,
    tagline: 'Crisp dosa topped with butter',
    location: 'Davanagere',
    description:
        'A thick, crisp dosa cooked with generous amounts of butter (benne), '
        'served with coconut chutney and potato palya.',
    highlights: ['Benne means butter', 'Served with chutney and palya'],
  ),
  DiscoverItem(
    id: 'holige',
    name: 'Holige (Obbattu)',
    kannadaName: 'ಹೋಳಿಗೆ',
    category: DiscoverCategory.food,
    kind: DiscoverKind.sweet,
    tagline: 'Sweet flatbread for festivals',
    location: 'Across Karnataka',
    description:
        'A flatbread stuffed with a sweet filling of chana dal and jaggery '
        'or coconut, served with ghee or milk on festivals such as Ugadi.',
    highlights: [
      'Filled with chana dal and jaggery, or coconut',
      'Made on Ugadi and other festivals',
    ],
  ),
  DiscoverItem(
    id: 'neer_dose',
    name: 'Neer Dose',
    kannadaName: 'ನೀರ್ ದೋಸೆ',
    category: DiscoverCategory.food,
    kind: DiscoverKind.dish,
    tagline: 'Soft, lacy rice crepes from the coast',
    location: 'Coastal Karnataka',
    description:
        'Thin, soft crepes made from a watery rice batter, with no '
        'fermentation. Neer means water. They are eaten with coconut chutney '
        'or chicken curry.',
    highlights: ['Neer means water', 'Needs no fermentation'],
  ),
  // Culture
  DiscoverItem(
    id: 'mysuru_dasara',
    name: 'Mysuru Dasara',
    kannadaName: 'ಮೈಸೂರು ದಸರಾ',
    category: DiscoverCategory.culture,
    kind: DiscoverKind.festival,
    tagline: 'Nada Habba, the state festival',
    location: 'Mysuru',
    description:
        'A ten-day festival celebrating the victory of goddess Chamundeshwari '
        'over the demon Mahishasura. It ends on Vijayadashami with the Jamboo '
        'Savari, a grand procession of decorated elephants.',
    highlights: [
      'Celebrated for more than 400 years',
      'Known as Nada Habba, the festival of the state',
      'Jamboo Savari elephant procession on the last day',
    ],
  ),
  DiscoverItem(
    id: 'yakshagana',
    name: 'Yakshagana',
    kannadaName: 'ಯಕ್ಷಗಾನ',
    category: DiscoverCategory.culture,
    kind: DiscoverKind.art,
    tagline: 'Dance-drama that lasts all night',
    location: 'Coastal Karnataka',
    description:
        'A traditional theatre form combining dance, music, dialogue and '
        'colourful costumes and headgear. Stories usually come from the '
        'Ramayana and Mahabharata.',
    highlights: [
      'Performed with chande drums and maddale',
      'Shows often run from night until dawn',
    ],
  ),
  DiscoverItem(
    id: 'kambala',
    name: 'Kambala',
    kannadaName: 'ಕಂಬಳ',
    category: DiscoverCategory.culture,
    kind: DiscoverKind.sport,
    tagline: 'Buffalo race in the paddy fields',
    location: 'Dakshina Kannada and Udupi',
    description:
        'A traditional race in which pairs of buffaloes, driven by a farmer, '
        'run through a slushy paddy-field track. It is held between November '
        'and March.',
    highlights: [
      'Held from November to March',
      'Run on wet paddy-field tracks',
    ],
  ),
  DiscoverItem(
    id: 'mysore_silk',
    name: 'Mysore Silk',
    kannadaName: 'ಮೈಸೂರು ರೇಷ್ಮೆ',
    category: DiscoverCategory.culture,
    kind: DiscoverKind.craft,
    tagline: 'Pure silk with real gold zari',
    location: 'Mysuru',
    description:
        'Mysore silk sarees are woven from pure mulberry silk, often with '
        'zari made of gold. Karnataka is the largest producer of mulberry '
        'silk in India.',
    highlights: [
      'Has a Geographical Indication (GI) tag',
      'Karnataka leads India in mulberry silk',
    ],
  ),
  DiscoverItem(
    id: 'channapatna_toys',
    name: 'Channapatna Toys',
    kannadaName: 'ಚನ್ನಪಟ್ಟಣದ ಬೊಂಬೆಗಳು',
    category: DiscoverCategory.culture,
    kind: DiscoverKind.craft,
    tagline: 'Colourful lacquered wooden toys',
    location: 'Ramanagara district',
    description:
        'Hand-turned wooden toys coloured with natural lacquer. Channapatna '
        'is known as Gombegala Ooru, the town of toys.',
    highlights: [
      'Has a Geographical Indication (GI) tag',
      'Channapatna is called the town of toys',
    ],
  ),
  // People
  DiscoverItem(
    id: 'kuvempu',
    name: 'Kuvempu',
    kannadaName: 'ಕುವೆಂಪು',
    category: DiscoverCategory.people,
    kind: DiscoverKind.writer,
    tagline: 'Rashtrakavi, poet of the state song',
    location: 'Poet, 1904–1994',
    description:
        'K. V. Puttappa, known as Kuvempu, was one of the greatest Kannada '
        'writers. He was the first Kannada writer to receive the Jnanpith '
        'Award and wrote the state song "Jaya Bharata Jananiya Tanujate".',
    highlights: [
      'Jnanpith Award in 1967 for Sri Ramayana Darshanam',
      'Honoured with the title Rashtrakavi (national poet)',
    ],
  ),
  DiscoverItem(
    id: 'basavanna',
    name: 'Basavanna',
    kannadaName: 'ಬಸವಣ್ಣ',
    category: DiscoverCategory.people,
    kind: DiscoverKind.leader,
    tagline: '12th-century philosopher and social reformer',
    location: 'Philosopher, 12th century',
    description:
        'Basavanna taught equality and the dignity of work through his '
        'vachanas, short poems in simple Kannada. He set up the Anubhava '
        'Mantapa, a forum for spiritual and social discussion.',
    highlights: [
      'Wrote vachanas in everyday Kannada',
      'Founded the Anubhava Mantapa',
      'Taught "Kayakave Kailasa": work is worship',
    ],
  ),
  DiscoverItem(
    id: 'rajkumar',
    name: 'Dr. Rajkumar',
    kannadaName: 'ಡಾ. ರಾಜ್‌ಕುಮಾರ್',
    category: DiscoverCategory.people,
    kind: DiscoverKind.artist,
    tagline: 'Annavru, legend of Kannada cinema',
    location: 'Actor and singer, 1929–2006',
    description:
        'Dr. Rajkumar acted in more than 200 Kannada films and was also a '
        'celebrated playback singer. He led the Gokak agitation for the '
        'primacy of Kannada in 1982.',
    highlights: [
      'Dadasaheb Phalke Award in 1995',
      'Fondly called Annavru (elder brother)',
    ],
  ),
  DiscoverItem(
    id: 'visvesvaraya',
    name: 'Sir M. Visvesvaraya',
    kannadaName: 'ಸರ್ ಎಂ. ವಿಶ್ವೇಶ್ವರಯ್ಯ',
    category: DiscoverCategory.people,
    kind: DiscoverKind.engineer,
    tagline: 'Engineer and Diwan of Mysore',
    location: 'Engineer, 1861–1962',
    description:
        'A visionary engineer who designed the Krishna Raja Sagara dam and '
        'served as Diwan of Mysore. India celebrates Engineers\' Day on his '
        'birthday, 15 September.',
    highlights: [
      'Bharat Ratna in 1955',
      'Chief engineer of the KRS dam',
      'Engineers\' Day is held on his birthday',
    ],
  ),
  DiscoverItem(
    id: 'kittur_chennamma',
    name: 'Kittur Rani Chennamma',
    kannadaName: 'ಕಿತ್ತೂರು ರಾಣಿ ಚೆನ್ನಮ್ಮ',
    category: DiscoverCategory.people,
    kind: DiscoverKind.leader,
    tagline: 'Queen who fought the British',
    location: 'Queen of Kittur, 1778–1829',
    description:
        'The queen of Kittur led an armed revolt against the British East '
        'India Company in 1824, decades before 1857. She is remembered as '
        'one of India\'s first freedom fighters.',
    highlights: [
      'Led the revolt of 1824',
      'Kittur Utsav is held every October in her memory',
    ],
  ),
  DiscoverItem(
    id: 'kempegowda',
    name: 'Kempe Gowda',
    kannadaName: 'ಕೆಂಪೇಗೌಡ',
    category: DiscoverCategory.people,
    kind: DiscoverKind.leader,
    tagline: 'Founder of Bengaluru',
    location: 'Chieftain, 16th century',
    description:
        'A chieftain under the Vijayanagara Empire who founded Bengaluru in '
        '1537, building a mud fort and planning markets (petes) and lakes.',
    highlights: [
      'Founded Bengaluru in 1537',
      'Bengaluru\'s airport is named after him',
    ],
  ),
];
