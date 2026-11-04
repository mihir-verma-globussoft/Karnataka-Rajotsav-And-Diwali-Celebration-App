# Game Developer Integration Guide: Shared Backend & Custom Player Avatars

This guide explains how any game in the **Karnataka Rajyotsava & Deepavali Celebration App** (such as **High Pitch / Low Pitch** or the **AR Diya Placement Game**) can:
1. **Use the player's custom camera selfie photo** as an in-game character sprite, avatar, or 3D texture.
2. **Connect to the shared Supabase backend** for high scores, statistics, and leaderboards without having to reinvent authentication or database logic.
3. **Participate in game-specific and combined festival leaderboards**.

---

## 1. System Architecture at a Glance

When a player launches the app:
1. They authenticate **once** using Google Sign-In.
2. They take a **live selfie photo** with their front camera during onboarding.
3. This selfie is uploaded to Supabase Storage (`player-avatars` bucket) and saved as `character_avatar_url` on their public profile.
4. **All games share this exact player session and selfie photo.**

```
               [Google Sign-In]
                      │
                      ▼
            [Camera Selfie Capture]
                      │
                      ▼
     ┌───────────────────────────────────┐
     │  Supabase Profiles & Storage      │
     │  - user_id                        │
     │  - username                       │
     │  - character_avatar_url (Selfie)  │
     └─────────────────┬─────────────────┘
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
 ┌────────────┐  ┌────────────┐  ┌────────────┐
 │Flappy Bird │  │ Pitch Game │  │  AR Game   │
 │ - Character│  │ - Character│  │ - AR Diya/ │
 │   Sprite   │  │   Sprite   │  │   Texture  │
 │ - Scores   │  │ - Scores   │  │ - Scores   │
 └────────────┘  └────────────┘  └────────────┘
```

---

## 2. How to Use the Player's Selfie Image in Your Game

Every player profile contains two image URLs:
* `player.characterAvatarUrl`: The camera selfie captured during onboarding.
* `player.avatarUrl`: The fallback Google profile picture.
* `player.displayAvatarUrl`: A built-in convenience getter returning `characterAvatarUrl ?? avatarUrl`.

---

### Step 2.1: Accessing the Current Player in Your Game Screen

You can access the player's profile in any Riverpod widget:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/flappy_bird_providers.dart';
import 'package:rajotsav_and_diwali_celebration_app/features/flappy_bird/domain/player.dart';

class MyGameScreen extends ConsumerWidget {
  const MyGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(flappyAuthStateProvider);

    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (PlayerProfile? player) {
        if (player == null) {
          return const Center(child: Text('Please sign in first'));
        }
        
        // Pass the player to your game canvas/widget:
        return MyGameCanvas(player: player);
      },
    );
  }
}
```

Or wrap your game route with `ProtectedFlappyPage`:
```dart
GoRoute(
  path: '/pitch_game/play',
  builder: (context, state) => ProtectedFlappyPage(
    title: 'Pitch Game',
    builder: (player) => PitchGameView(player: player),
  ),
),
```

---

### Step 2.2: Pre-caching the Image for 60 FPS Smooth Gameplay

> [!IMPORTANT]
> To prevent stuttering or frame drops when the game starts, **pre-cache** the player's avatar in `didChangeDependencies` before the game loop starts.

```dart
class _MyGameViewState extends ConsumerState<MyGameView> {
  bool _preloaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final avatarUrl = widget.player.displayAvatarUrl;
    if (!_preloaded && avatarUrl != null) {
      _preloaded = true;
      precacheImage(NetworkImage(avatarUrl), context);
    }
  }
  ...
}
```

---

### Step 2.3: Rendering as a 2D In-Game Character / Sprite (Flutter Widget / Canvas)

Here is the exact pattern used in **Flappy Bird** to turn the selfie into a circular player token with a glowing festive border:

```dart
class PlayerCharacterSprite extends StatelessWidget {
  const PlayerCharacterSprite({
    required this.player,
    this.size = 50.0,
    super.key,
  });

  final PlayerProfile player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = player.displayAvatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFC94A), // Festival Gold background
        border: Border.all(color: const Color(0xFFFFD166), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99FF9E32),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? Center(
              child: Text(
                player.username.isEmpty
                    ? '?'
                    : player.username.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low, // Best for smooth animation
              errorBuilder: (_, __, ___) => Center(
                child: Text(player.username.characters.first.toUpperCase()),
              ),
            ),
    );
  }
}
```

#### Moving the Character Around:
Position it inside a `Stack` or animate it based on your game physics (e.g. pitch height, tap jump):
```dart
Positioned(
  left: characterX,
  top: characterY,
  child: Transform.rotate(
    angle: rotationAngle,
    child: PlayerCharacterSprite(player: widget.player),
  ),
)
```

---

### Step 2.4: Using as a 3D Texture / Billboard in AR Game

If you are developing the **AR Game** (e.g., placing the player's face inside an AR Diya lantern, a floating festive coin, or a 3D model):

1. **Obtain the Image Bytes**:
   ```dart
   import 'package:http/http.dart' as http;
   import 'dart:typed_data';

   Future<Uint8List?> fetchAvatarBytes(String avatarUrl) async {
     try {
       final response = await http.get(Uri.parse(avatarUrl));
       if (response.statusCode == 200) {
         return response.bodyBytes;
       }
     } catch (e) {
       debugPrint('Failed to load avatar bytes: $e');
     }
     return null;
   }
   ```
2. **Pass to Platform Channel / AR Plugin**:
   Pass the `Uint8List` bytes or cached local file path across your `MethodChannel` to OpenGL / SceneKit / ARCore / Filament to bind it as a material texture.

---

## 3. Registering Your Game in the Database

Each game must have a unique `slug` (3 to 48 characters, matching `^[a-z0-9_]{3,48}$`).

To register your game in the production Supabase database, create a migration file in `supabase/migrations/` (e.g. `supabase/migrations/202611030007_register_pitch_game.sql`):

```sql
begin;

insert into public.games (
  slug,
  display_name,
  max_score,
  max_duration_ms,
  minimum_ms_per_score,
  is_active
) values (
  'pitch_game',             -- Your game's unique identifier
  'High Pitch / Low Pitch', -- Human-readable name
  50000,                    -- Max legitimate score (anti-cheat limit)
  1800000,                  -- Max gameplay duration in ms (e.g. 30 minutes)
  20,                       -- Min ms per score increment (anti-cheat plausibility)
  true                      -- Active for submissions
)
on conflict (slug) do update set
  display_name = excluded.display_name,
  max_score = excluded.max_score,
  max_duration_ms = excluded.max_duration_ms,
  minimum_ms_per_score = excluded.minimum_ms_per_score,
  is_active = true;

commit;
```

---

## 4. Connecting Your Game to the Backend

### Step 4.1: Define Your Game's Repository Provider

In your feature provider file (e.g., `lib/features/pitch_game/pitch_game_providers.dart`), instantiate a `SupabasePlayerRepository` scoped to your `gameSlug`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../flappy_bird/data/supabase_player_repository.dart';
import '../flappy_bird/domain/player_repository.dart';

final pitchGameRepositoryProvider = Provider<PlayerRepository>((ref) {
  return SupabasePlayerRepository(
    Supabase.instance.client,
    gameSlug: 'pitch_game', // Your registered slug!
  );
});
```

---

### Step 4.2: Submitting Scores on Game Over

When a round starts:
1. Generate an idempotency `gameId = const Uuid().v4();`.
2. Record `startedAt = DateTime.now();`.

When game over occurs:
3. Submit the result:

```dart
import 'package:uuid/uuid.dart';
import '../flappy_bird/domain/game_result.dart';

class PitchGameController {
  PitchGameController(this.repository);
  final PlayerRepository repository;

  late String _gameId;
  late DateTime _startedAt;

  void onGameStart() {
    _gameId = const Uuid().v4();
    _startedAt = DateTime.now();
  }

  Future<GameSubmission> onGameOver(int finalScore) async {
    final elapsed = DateTime.now().difference(_startedAt);

    final result = GameResult(
      gameId: _gameId,
      gameSlug: 'pitch_game',
      score: finalScore,
      duration: elapsed,
      startedAt: _startedAt,
    );

    // Submits atomically to Supabase via RPC
    final submission = await repository.submitGame(result);
    
    // submission contains:
    // submission.highScore (int)
    // submission.isNewHighScore (bool)
    // submission.totalGames (int)
    // submission.totalScore (int)
    return submission;
  }
}
```

> [!TIP]
> **Offline Support**: For automatic offline queueing and retrying when connection is restored, wrap your call with `ScoreSubmissionService`:
> ```dart
> final submissionService = ref.read(scoreSubmissionServiceProvider);
> await submissionService.submit(result);
> ```

---

### Step 4.3: Fetching the Game Leaderboard

To display your game's leaderboard table:

```dart
final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(pitchGameRepositoryProvider);
  return repo.loadLeaderboard(offset: 0, limit: 20);
});
```

In your UI:
```dart
leaderboardAsync.when(
  data: (entries) => ListView.builder(
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final item = entries[index];
      return ListTile(
        leading: Text('#${item.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
        title: Text(item.username),
        subtitle: Text('Score: ${item.highScore}'),
        trailing: CircleAvatar(
          backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
          child: item.avatarUrl == null ? Text(item.username[0]) : null,
        ),
      );
    },
  ),
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('Could not load leaderboard: $err'),
);
```

---

### Step 4.4: Fetching the Player's Game Statistics

To display the player's personal stats for your game:

```dart
final pitchStatsProvider = FutureProvider.autoDispose<PlayerStats>((ref) async {
  final repo = ref.watch(pitchGameRepositoryProvider);
  return repo.loadStats();
});
```

Returns:
* `stats.highScore`: Player's highest score in this game.
* `stats.totalGames`: Total times played.
* `stats.totalScore`: Cumulative score.
* `stats.globalRank`: Player's current global position (e.g. `#1`, `#4`), or `null` if they haven't played yet.

---

## 5. Combined / Grand Festival Leaderboard

Because every game records results to `public.player_game_stats` with the same `user_id`, we can query combined scores across all games at any time.

### How Combined Scores Work:
* **Sum of High Scores**: $\text{Grand Score} = \text{Flappy Best} + \text{Pitch Best} + \text{AR Best}$
* **Cumulative Festival Points**: $\sum \text{Total Score across all games}$

### Combined Leaderboard SQL Query:
```sql
select
  row_number() over (
    order by sum(stats.high_score) desc, min(stats.high_score_achieved_at) asc
  ) as overall_rank,
  stats.user_id,
  profile.username,
  profile.character_avatar_url,
  sum(stats.high_score) as combined_score,
  count(distinct stats.game_slug) as games_played
from public.player_game_stats as stats
join public.profiles as profile on profile.id = stats.user_id
group by stats.user_id, profile.username, profile.character_avatar_url
order by combined_score desc;
```

---

## 6. Summary Checklist for Game Developers

When integrating a new game:
- [ ] Add your game slug to `public.games` in a new SQL migration.
- [ ] Read the authenticated player via `ref.watch(flappyAuthStateProvider)`.
- [ ] Pre-cache the avatar with `precacheImage(NetworkImage(player.displayAvatarUrl), context)`.
- [ ] Use `PlayerCharacterSprite` or `player.displayAvatarUrl` to render their selfie as the character.
- [ ] Create `SupabasePlayerRepository(client, gameSlug: 'your_game_slug')`.
- [ ] Generate one `Uuid().v4()` at the beginning of each game run.
- [ ] Submit final scores via `repository.submitGame(result)`.
- [ ] Use `repository.loadLeaderboard(...)` and `repository.loadStats()` for ranking screens.

