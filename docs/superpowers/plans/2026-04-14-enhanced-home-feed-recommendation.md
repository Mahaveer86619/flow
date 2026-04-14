# Enhanced Home Feed & Recommendation System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a sophisticated, lightweight recommendation system and fix the home feed shelf ordering and mapping.

**Architecture:** Hybrid system using YTMusic data and a local tracking layer (play counts, genres, search history).

**Tech Stack:** Python (FastAPI, SQLAlchemy, ytmusicapi), Flutter.

---

### Task 1: Backend Database Models & Migrations

**Files:**
- Modify: `flow-source/app/models.py`

- [ ] **Step 1: Add new models for tracking interactions and recommendations**

```python
class UserSongInteraction(Base):
    __tablename__ = "user_song_interactions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    song_id = Column(String, index=True)
    play_count = Column(Integer, default=0)
    repeat_count = Column(Integer, default=0) # Consecutive plays
    last_played_at = Column(DateTime, default=datetime.utcnow)
    genre_tags = Column(Text, nullable=True) # JSON string
    
    user = relationship("User", back_populates="interactions")

class UserRecommendation(Base):
    __tablename__ = "user_recommendations"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    song_id = Column(String, index=True)
    data = Column(Text) # JSON serialized SongResponse
    score = Column(Float, default=0.0)
    updated_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="recommendations")

# Update User model to include relationships
# class User(Base):
#     ...
#     interactions = relationship("UserSongInteraction", back_populates="user", cascade="all, delete-orphan")
#     recommendations = relationship("UserRecommendation", back_populates="user", cascade="all, delete-orphan")
```

- [ ] **Step 2: Run the app to trigger `Base.metadata.create_all`**

Run: `cd flow-source && python -m app.main`
Expected: "Database tables initialized." in logs.

- [ ] **Step 3: Commit**

```bash
git add flow-source/app/models.py
git commit -m "feat: add user song interaction and recommendation models"
```

---

### Task 2: Interaction Tracking Service

**Files:**
- Modify: `flow-source/app/services.py`
- Modify: `flow-source/app/routes.py`

- [ ] **Step 1: Implement `track_interaction` in `YTMusicService`**

```python
def track_interaction(self, db: Session, user: User, song_id: str, genres: Optional[List[str]] = None):
    interaction = db.query(UserSongInteraction).filter(
        UserSongInteraction.user_id == user.id,
        UserSongInteraction.song_id == song_id
    ).first()
    
    if not interaction:
        interaction = UserSongInteraction(
            user_id=user.id,
            song_id=song_id,
            play_count=1,
            genre_tags=json.dumps(genres) if genres else None
        )
        db.add(interaction)
    else:
        interaction.play_count += 1
        interaction.last_played_at = datetime.utcnow()
        if genres:
            existing_genres = json.loads(interaction.genre_tags) if interaction.genre_tags else []
            updated_genres = list(set(existing_genres + genres))
            interaction.genre_tags = json.dumps(updated_genres)
    
    db.commit()
```

- [ ] **Step 2: Call `track_interaction` when a song is played/streamed**

Find playback endpoints in `routes.py` and ensure interaction is recorded.

- [ ] **Step 3: Commit**

```bash
git add flow-source/app/services.py flow-source/app/routes.py
git commit -m "feat: implement user interaction tracking"
```

---

### Task 3: Improved Home Feed Shelf Logic

**Files:**
- Modify: `flow-source/app/services.py`

- [ ] **Step 1: Enhance `_classify_shelf` with better keyword matching**

```python
# Add more robust keywords to self._shelf_map
(["quick pick", "top pick", "start radio", "picks", "suggested"], "quickPicks"),
(["listen again", "listening again", "continue", "recent", "replay"], "listeningAgain"),
```

- [ ] **Step 2: Robust fallback for missing shelves in `build_home_data`**

Ensure `quickPicks` and `listeningAgain` are ALWAYS populated using library/history if `ytm.get_home()` doesn't provide them.

- [ ] **Step 3: Commit**

```bash
git add flow-source/app/services.py
git commit -m "fix: improve home feed shelf classification and fallbacks"
```

---

### Task 4: Recommendation Engine ("Fresh Picks")

**Files:**
- Modify: `flow-source/app/services.py`

- [ ] **Step 1: Implement `generate_recommendations` in `YTMusicService`**

```python
def generate_recommendations(self, db: Session, user: User, ytm, proxy_base: Optional[str] = None):
    # 1. Get seeds from local interactions and history
    # 2. Use ytm.get_watch_playlist(videoId=seed_id) for related tracks
    # 3. Mix in genre-based trends from get_explore()
    # 4. Filter and rank
    # 5. Persist to UserRecommendation table
```

- [ ] **Step 2: Update `_get_fresh_picks` to use the new engine**

- [ ] **Step 3: Commit**

```bash
git add flow-source/app/services.py
git commit -m "feat: implement advanced recommendation engine"
```

---

### Task 5: Frontend Home Screen Reordering

**Files:**
- Modify: `flow/lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Enforce shelf order in `_HomeScreenContent`**

```dart
// Update reordering logic to ensure:
// 1. quickPicks
// 2. listeningAgain
// 3. freshFinds (our recommendations)
// 4. trending
```

- [ ] **Step 2: Commit**

```bash
git add flow/lib/presentation/screens/home/home_screen.dart
git commit -m "ui: enforce strict shelf ordering on home screen"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Run full system and check logs for recommendation generation**
- [ ] **Step 2: Verify shelf order on mobile emulator or web**
- [ ] **Step 3: Verify interaction tracking in SQLite**
