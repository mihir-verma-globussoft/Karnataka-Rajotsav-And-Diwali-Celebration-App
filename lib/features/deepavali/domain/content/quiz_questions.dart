/// Topic of a quiz question.
enum QuizCategory { traditions, culture, food, celebrations, folklore }

/// One multiple-choice question. [options] are in authored order; the session
/// shuffles them, so [correctIndex] refers to this authored order.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Shown after answering, right or wrong.
  final String explanation;
  final QuizCategory category;
}

/// Question pool. A run draws [quizLength] of these at random. Folklore is
/// phrased as tradition ("according to tradition"), not as fact. Every answer
/// is a widely documented one (see Wikipedia: Diwali and the linked articles).
const int quizLength = 10;

const List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    id: 'meaning',
    prompt: 'What does “Deepavali” mean?',
    options: [
      'A row of lamps',
      'A festival of colours',
      'A night of stars',
      'A harvest feast',
    ],
    correctIndex: 0,
    explanation:
        'It comes from the Sanskrit deepa (lamp) and avali (row), so “a row '
        'of lamps”. Diwali is the shortened form.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'lakshmi',
    prompt:
        'Which goddess of wealth is worshipped on the main night of Diwali?',
    options: ['Lakshmi', 'Saraswati', 'Parvati', 'Durga'],
    correctIndex: 0,
    explanation:
        'Lakshmi Puja is performed on the evening of the main day, when homes '
        'are lit so that the goddess is welcomed in.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'diya',
    prompt: 'What are the small clay oil lamps lit at Diwali called?',
    options: ['Diyas', 'Toranas', 'Kalash', 'Dholaks'],
    correctIndex: 0,
    explanation:
        'Diyas are small oil lamps, usually of clay, with a cotton wick. '
        'Rows of them give the festival its name.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'rangoli',
    prompt:
        'What are the colourful patterns made at the doorstep with powder or '
        'flowers called?',
    options: ['Rangoli', 'Mehndi', 'Bandhani', 'Warli'],
    correctIndex: 0,
    explanation:
        'Rangoli is floor art made from coloured powders, rice, petals or '
        'sand. It is made to welcome guests and, by tradition, good fortune.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'dhanteras',
    prompt:
        'Dhanteras opens the Diwali festival. What do many families '
        'traditionally buy that day?',
    options: [
      'Gold, silver or new utensils',
      'Woollen clothes',
      'Fresh flowers only',
      'Sugarcane',
    ],
    correctIndex: 0,
    explanation:
        'Dhanteras is considered an auspicious day to buy gold, silver or '
        'new kitchen utensils.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'bhai_dooj',
    prompt: 'Which relationship does Bhai Dooj, the fifth day, celebrate?',
    options: [
      'Brothers and sisters',
      'Parents and children',
      'Teachers and students',
      'Neighbours',
    ],
    correctIndex: 0,
    explanation:
        'On Bhai Dooj sisters pray for their brothers’ well-being and '
        'brothers give gifts in return.',
    category: QuizCategory.traditions,
  ),
  QuizQuestion(
    id: 'five_days',
    prompt: 'How many days does the main Diwali festival traditionally last?',
    options: ['Five', 'One', 'Three', 'Ten'],
    correctIndex: 0,
    explanation:
        'The festival runs for five days, from Dhanteras to Bhai Dooj, with '
        'Lakshmi Puja on the third day.',
    category: QuizCategory.celebrations,
  ),
  QuizQuestion(
    id: 'new_moon',
    prompt: 'On which phase of the moon does the main Diwali night fall?',
    options: ['New moon', 'Full moon', 'Half moon', 'Crescent after sunset'],
    correctIndex: 0,
    explanation:
        'Diwali falls on the new-moon night (amavasya) of the month of '
        'Kartika, the darkest night of the month. That is why so many lamps '
        'are lit.',
    category: QuizCategory.celebrations,
  ),
  QuizQuestion(
    id: 'muhurat',
    prompt:
        'What special session do Indian stock exchanges hold on Diwali '
        'evening?',
    options: [
      'Muhurat trading',
      'Night-long auction',
      'Charity trading',
      'A closed market',
    ],
    correctIndex: 0,
    explanation:
        'Muhurat trading is a short session held at an auspicious time on '
        'Diwali evening, announced in advance by the exchanges.',
    category: QuizCategory.celebrations,
  ),
  QuizQuestion(
    id: 'singapore',
    prompt: 'In which of these countries is Diwali a public holiday?',
    options: ['Singapore', 'Japan', 'Germany', 'Brazil'],
    correctIndex: 0,
    explanation:
        'Diwali is an official holiday in several countries outside India, '
        'including Nepal, Sri Lanka, Malaysia, Singapore, Fiji and Mauritius.',
    category: QuizCategory.celebrations,
  ),
  QuizQuestion(
    id: 'kali',
    prompt:
        'In Bengal, which goddess is worshipped on the night of Diwali as '
        'Kali Puja?',
    options: ['Kali', 'Annapurna', 'Saraswati', 'Sita'],
    correctIndex: 0,
    explanation:
        'In Bengal and parts of eastern India the new-moon night is devoted '
        'to Kali Puja, also called Shyama Puja.',
    category: QuizCategory.culture,
  ),
  QuizQuestion(
    id: 'bandi_chhor',
    prompt:
        'Sikhs mark Bandi Chhor Divas around Diwali. Whose release from '
        'Gwalior Fort does it remember?',
    options: [
      'Guru Hargobind',
      'Guru Nanak',
      'Guru Gobind Singh',
      'Guru Arjan',
    ],
    correctIndex: 0,
    explanation:
        'Bandi Chhor Divas (Day of Liberation) remembers Guru Hargobind’s '
        'release from Gwalior Fort. The Golden Temple in Amritsar is lit up '
        'for it.',
    category: QuizCategory.culture,
  ),
  QuizQuestion(
    id: 'jain',
    prompt: 'For Jains, Diwali marks the moksha (liberation) of whom?',
    options: ['Mahavira', 'Rishabhanatha', 'Gautama Buddha', 'Adi Shankara'],
    correctIndex: 0,
    explanation:
        'Jains observe Diwali as the day Mahavira, the last Tirthankara, '
        'attained moksha.',
    category: QuizCategory.culture,
  ),
  QuizQuestion(
    id: 'varanasi',
    prompt:
        'Which city lights its Ganga ghats with lamps for Dev Deepawali, '
        'about two weeks after Diwali?',
    options: ['Varanasi', 'Jaipur', 'Mumbai', 'Kolkata'],
    correctIndex: 0,
    explanation:
        'Dev Deepawali falls on Kartika Purnima, roughly 15 days after '
        'Diwali. Varanasi’s ghats are lit with thousands of diyas.',
    category: QuizCategory.culture,
  ),
  QuizQuestion(
    id: 'ayodhya',
    prompt:
        'Which city holds a large public lamp-lighting called Deepotsav on '
        'the eve of Diwali?',
    options: ['Ayodhya', 'Pune', 'Chennai', 'Bhopal'],
    correctIndex: 0,
    explanation:
        'Ayodhya, linked by tradition with Rama, lights its riverfront ghats '
        'with lamps. A 2023 event set a record with 2,223,676 lamps.',
    category: QuizCategory.culture,
  ),
  QuizQuestion(
    id: 'jalebi',
    prompt:
        'Which sweet is made by frying spirals of batter and soaking them in '
        'sugar syrup?',
    options: ['Jalebi', 'Rasgulla', 'Kaju katli', 'Peda'],
    correctIndex: 0,
    explanation:
        'Jalebi is a deep-fried batter spiral soaked in syrup, a favourite '
        'at festivals across India.',
    category: QuizCategory.food,
  ),
  QuizQuestion(
    id: 'kaju',
    prompt: 'Which nut is the main ingredient of kaju katli?',
    options: ['Cashew', 'Almond', 'Peanut', 'Pistachio'],
    correctIndex: 0,
    explanation:
        'Kaju means cashew. Kaju katli is a diamond-shaped sweet made from '
        'ground cashews, sugar and ghee.',
    category: QuizCategory.food,
  ),
  QuizQuestion(
    id: 'besan_ladoo',
    prompt:
        'Which Diwali sweet is made by roasting besan (gram flour) in ghee?',
    options: ['Besan ladoo', 'Rasmalai', 'Kheer', 'Shrikhand'],
    correctIndex: 0,
    explanation:
        'Besan ladoo is gram flour roasted in ghee, mixed with sugar and '
        'shaped into balls.',
    category: QuizCategory.food,
  ),
  QuizQuestion(
    id: 'faral',
    prompt:
        'In Maharashtra, the plate of sweet and savoury Diwali snacks is '
        'known as what?',
    options: ['Faral', 'Chaat', 'Prasad', 'Thali'],
    correctIndex: 0,
    explanation:
        'Diwali faral includes snacks such as chakli, chivda, karanji and '
        'ladoo, shared with family and visitors.',
    category: QuizCategory.food,
  ),
  QuizQuestion(
    id: 'rama',
    prompt:
        'According to tradition, whose return to Ayodhya is remembered by '
        'many Hindus at Diwali?',
    options: ['Rama', 'Krishna', 'Hanuman', 'Arjuna'],
    correctIndex: 0,
    explanation:
        'Many Hindus remember Rama’s return to Ayodhya after defeating '
        'Ravana, welcomed by a city lit with lamps.',
    category: QuizCategory.folklore,
  ),
  QuizQuestion(
    id: 'naraka',
    prompt:
        'Naraka Chaturdashi, the second day, remembers the defeat of which '
        'demon king by Krishna?',
    options: ['Narakasura', 'Ravana', 'Mahishasura', 'Hiranyakashipu'],
    correctIndex: 0,
    explanation:
        'In tradition, Krishna defeated the demon king Narakasura. The '
        'second day is also called Choti Diwali.',
    category: QuizCategory.folklore,
  ),
  QuizQuestion(
    id: 'bali',
    prompt:
        'Balipratipada remembers which king, who by tradition was sent to '
        'the underworld by Vamana?',
    options: ['Bali', 'Janaka', 'Harishchandra', 'Dasharatha'],
    correctIndex: 0,
    explanation:
        'In the story of Vamana, the generous king Bali was granted a yearly '
        'visit to his people, remembered on Balipratipada.',
    category: QuizCategory.folklore,
  ),
  QuizQuestion(
    id: 'ocean',
    prompt:
        'According to tradition, Lakshmi emerged from the churning of what?',
    options: [
      'The ocean of milk',
      'The river Ganga',
      'The Himalayas',
      'A forest fire',
    ],
    correctIndex: 0,
    explanation:
        'The story of Samudra Manthan tells of the gods and demons churning '
        'the ocean of milk, from which Lakshmi emerged.',
    category: QuizCategory.folklore,
  ),
];
