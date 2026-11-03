import 'text_tools.dart';

/// The four card designs.
enum GreetingDesign {
  goldenDiyas('Golden Diyas'),
  rangoliBorder('Rangoli Border'),
  nightLanterns('Night Sky Lanterns'),
  marigoldGarland('Marigold Garland');

  const GreetingDesign(this.label);
  final String label;
}

/// Most characters in the message.
const int greetingMessageMax = 120;

/// Most characters in the sender's name.
const int greetingNameMax = 30;

/// Ready-made wishes the user can pick instead of typing.
const List<String> greetingPresets = [
  'Wishing you a bright and happy Deepavali!',
  'May the festival of lights fill your home with joy and prosperity.',
  'Light a diya, share a smile. Happy Deepavali!',
  'May this Deepavali bring you health, happiness and peace.',
];

/// Caption sent along with the picture.
const String greetingShareText = 'Wishing you a bright and happy Deepavali!';

/// Immutable greeting card. Text is cleaned on the way in, so a card can
/// never hold an over-long message or a blank-looking name.
class GreetingCard {
  const GreetingCard({
    this.design = GreetingDesign.goldenDiyas,
    this.message = '',
    this.from = '',
  });

  /// The card a user starts with.
  factory GreetingCard.initial() =>
      GreetingCard(message: greetingPresets.first);

  final GreetingDesign design;
  final String message;

  /// Sender name; empty when none.
  final String from;

  bool get hasFrom => from.isNotEmpty;
  bool get hasMessage => message.isNotEmpty;

  /// See [cleanText].
  static String clean(String input, int max) => cleanText(input, max);

  GreetingCard withDesign(GreetingDesign value) =>
      value == design ? this : _copy(design: value);

  GreetingCard withMessage(String value) =>
      _copy(message: clean(value, greetingMessageMax));

  GreetingCard withFrom(String value) =>
      _copy(from: clean(value, greetingNameMax));

  GreetingCard _copy({GreetingDesign? design, String? message, String? from}) =>
      GreetingCard(
        design: design ?? this.design,
        message: message ?? this.message,
        from: from ?? this.from,
      );

  /// Text used for the card and by screen readers.
  String get summary {
    final body = hasMessage ? message : 'Happy Deepavali';
    return 'Greeting card, ${design.label}: $body'
        '${hasFrom ? ', from $from' : ''}';
  }

  @override
  bool operator ==(Object other) =>
      other is GreetingCard &&
      other.design == design &&
      other.message == message &&
      other.from == from;

  @override
  int get hashCode => Object.hash(design, message, from);
}
