-- ════════════════════════════════════════════
--  Libro Perpetuo — Supabase Schema
--  Run this in Supabase SQL Editor
--  Dessign Innovation — 2026
-- ════════════════════════════════════════════

-- ── TITLES ────────────────────────────────────────────────────
create table titles (
  id            text primary key,          -- e.g. "alice_wonderland"
  title         text not null,
  author        text not null,
  language      varchar(5) default 'en',
  total_pages   int not null,
  slot          int not null               -- 100,250,500,750,1000
                check (slot in (100,250,500,750,1000)),
  cover_url     text,
  description   text,
  published_at  timestamptz,
  created_at    timestamptz default now()
);

-- ── PAGES (content per page per title) ───────────────────────
create table pages (
  id            bigserial primary key,
  title_id      text references titles(id) on delete cascade,
  page_number   int not null,
  chapter_title text,
  text_content  text not null,
  image_url     text,
  has_image     boolean default false,
  font_style    varchar(10) default 'serif', -- serif|sans|mono
  word_count    int,
  created_at    timestamptz default now(),
  unique(title_id, page_number)
);

-- ── USERS ─────────────────────────────────────────────────────
create table user_library (
  id            bigserial primary key,
  user_id       uuid references auth.users(id) on delete cascade,
  title_id      text references titles(id),
  purchased_at  timestamptz default now(),
  last_page     int default 1,
  last_read_at  timestamptz,
  unique(user_id, title_id)
);

-- ── READING PROGRESS ──────────────────────────────────────────
create table reading_progress (
  id            bigserial primary key,
  user_id       uuid references auth.users(id) on delete cascade,
  title_id      text references titles(id),
  page_number   int not null,
  synced_at     timestamptz default now(),
  unique(user_id, title_id)
);

-- ── ROW LEVEL SECURITY ────────────────────────────────────────
alter table titles         enable row level security;
alter table pages          enable row level security;
alter table user_library   enable row level security;
alter table reading_progress enable row level security;

-- Titles: public read
create policy "Titles are publicly readable"
  on titles for select using (true);

-- Pages: readable only if user owns the title
create policy "Pages readable if title in library"
  on pages for select using (
    exists (
      select 1 from user_library ul
      where ul.user_id = auth.uid()
        and ul.title_id = pages.title_id
    )
  );

-- Demo titles: always readable (for PoC)
create policy "Demo titles always readable"
  on pages for select using (
    title_id in ('alice_wonderland', 'demo_sardinia', 'moby_dick')
  );

-- User library: own rows only
create policy "Users can CRUD their own library"
  on user_library for all using (user_id = auth.uid());

-- Reading progress: own rows only
create policy "Users can CRUD their own progress"
  on reading_progress for all using (user_id = auth.uid());

-- ── INDEXES ───────────────────────────────────────────────────
create index idx_pages_title_page on pages(title_id, page_number);
create index idx_user_library_user on user_library(user_id);
create index idx_progress_user_title on reading_progress(user_id, title_id);

-- ── DEMO DATA INSERT ──────────────────────────────────────────
insert into titles (id, title, author, language, total_pages, slot, description) values
('alice_wonderland', 'Alice''s Adventures in Wonderland', 'Lewis Carroll', 'en', 96, 100,
 'Lewis Carroll''s classic tale of a girl who falls down a rabbit hole into a fantasy world.'),
('moby_dick', 'Moby Dick', 'Herman Melville', 'en', 427, 500,
 'The epic story of Captain Ahab''s obsessive quest for the white whale.'),
('demo_sardinia', 'Sardinia — A Cultural Guide', 'Dessign Innovation', 'en', 88, 100,
 'An immersive guide to the landscapes, culture and ancient civilisation of Sardinia.');

-- Alice pages (sample)
insert into pages (title_id, page_number, chapter_title, text_content, word_count) values
('alice_wonderland', 1, 'Chapter I — Down the Rabbit Hole',
 'Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, ''and what is the use of a book,'' thought Alice, ''without pictures or conversations?''', 62),
('alice_wonderland', 2, 'Chapter I — Down the Rabbit Hole',
 'So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.', 52),
('alice_wonderland', 3, 'Chapter I — Down the Rabbit Hole',
 'There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, ''Oh dear! Oh dear! I shall be late!''', 34);
