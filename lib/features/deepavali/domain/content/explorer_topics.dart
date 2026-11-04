/// One topic card in the Discover Deepavali section. Pure data.
class ExplorerTopic {
  const ExplorerTopic({
    required this.id,
    required this.title,
    required this.teaser,
    required this.paragraphs,
    this.regionalNote,
    this.didYouKnow,
  });

  /// Stable id; the presentation layer maps it to an icon.
  final String id;
  final String title;

  /// One short line shown on the card.
  final String teaser;

  /// Two to four short paragraphs shown in the sheet.
  final List<String> paragraphs;

  /// How customs differ by region.
  final String? regionalNote;
  final String? didYouKnow;
}

/// Id of the topic that opens the five-day timeline instead of text.
const String fiveDaysTopicId = 'five_days';

const List<ExplorerTopic> explorerTopics = [
  ExplorerTopic(
    id: 'significance',
    title: 'Significance',
    teaser: 'Light over darkness, good over evil.',
    paragraphs: [
      'Deepavali comes from the Sanskrit words deepa (lamp) and avali (row): '
          'the festival of rows of lights. Across communities it stands for '
          'the victory of light over darkness, knowledge over ignorance and '
          'good over evil.',
      'It is also a time to renew: homes are cleaned, debts and quarrels '
          'are settled where possible, and families come together.',
    ],
    regionalNote:
        'The story behind the festival changes with the region and faith. '
        'Many Hindus in North India remember Rama’s return to Ayodhya, in '
        'South India the victory of Krishna over Narakasura is central, '
        'Jains remember Mahavira’s nirvana, and Sikhs observe Bandi Chhor '
        'Divas.',
    didYouKnow:
        'Deepavali is also written Diwali; both come from the same word.',
  ),
  ExplorerTopic(
    id: 'traditions',
    title: 'Traditions',
    teaser: 'Lamps, new clothes, gifts and family.',
    paragraphs: [
      'Homes are cleaned and decorated, and oil lamps (diyas) are lit at '
          'dusk and kept glowing through the nights of the festival.',
      'People wear new clothes, visit relatives, exchange gifts and share '
          'sweets and snacks with neighbours and friends.',
      'Fireworks are part of the celebration in many places. Many cities now '
          'encourage quieter, lower-smoke options, and it is kinder to '
          'pets, elders and the air.',
    ],
    regionalNote:
        'In Karnataka the festival often begins before dawn with an oil bath '
        '(abhyanga snana) on Naraka Chaturdashi, followed by new clothes and '
        'lamps at the door.',
  ),
  ExplorerTopic(
    id: 'rangoli',
    title: 'Rangoli',
    teaser: 'Colourful floor art to welcome guests.',
    paragraphs: [
      'Rangoli is made at the entrance of the home with coloured powder, '
          'rice flour or flower petals. Patterns are often symmetrical: '
          'lotuses, diyas, peacocks and geometric stars.',
      'It is a way of welcoming guests and, in the Lakshmi Puja tradition, '
          'the goddess of prosperity herself.',
    ],
    regionalNote:
        'The art has many names and styles: kolam in Tamil Nadu, muggu in '
        'Andhra Pradesh and Telangana, alpana in Bengal, and rangoli in '
        'Karnataka and Maharashtra.',
    didYouKnow: 'You can try your own in the Rangoli Studio below.',
  ),
  ExplorerTopic(
    id: 'sweets',
    title: 'Festive sweets',
    teaser: 'Laddu, jalebi, karjikai and more.',
    paragraphs: [
      'Sweets are the heart of the festival kitchen. Boxes of mithai '
          'travel between homes, and guests rarely leave empty-handed.',
      'Popular choices include laddu, barfi, kaju katli, gulab jamun and '
          'jalebi, usually made with milk, ghee, sugar and nuts.',
    ],
    regionalNote:
        'Karnataka kitchens often make karjikai, chakli, kodubale and '
        'holige alongside sweets from other regions. Bengal is known for '
        'sandesh and rasgulla, and Maharashtra for karanji and chakli.',
  ),
  ExplorerTopic(
    id: 'rituals',
    title: 'Rituals',
    teaser: 'Lakshmi Puja and lighting the lamps.',
    paragraphs: [
      'On Lakshmi Puja evening, many families clean the house, light '
          'lamps at every threshold and worship Lakshmi, often together '
          'with Ganesha, offering flowers, sweets and prayers.',
      'Some business communities begin a new account book at this time, '
          'asking for a prosperous year ahead.',
      'Keep lit lamps away from curtains and clothing, and never leave them '
          'unattended around children.',
    ],
    regionalNote:
        'In Bengal the same night is Kali Puja, and in parts of Gujarat the '
        'day after Diwali is the start of the new year.',
  ),
  ExplorerTopic(
    id: fiveDaysTopicId,
    title: 'Five days of Diwali',
    teaser: 'Dhanteras to Bhai Dooj, day by day.',
    paragraphs: [],
  ),
];
