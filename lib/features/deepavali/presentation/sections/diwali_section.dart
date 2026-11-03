/// The sections of the Deepavali page, in scroll order. Each owns a key so the
/// hero button can scroll to it; [title] is the heading it shows.
enum DiwaliSection {
  countdown('Celebration countdown'),
  explorer('Discover Deepavali'),
  destinations('Deepavali Around India'),
  diyaGame('Light the Diyas'),
  quiz('Deepavali Quiz'),
  rangoli('Rangoli Studio'),
  greeting('Greeting Card'),
  more('More to Explore');

  const DiwaliSection(this.title);

  final String title;
}
