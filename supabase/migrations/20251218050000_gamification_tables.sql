-- Migration: Tables pour système de gamification
-- Badges, Points, Niveaux, Challenges

-- Table principale de gamification utilisateur
CREATE TABLE IF NOT EXISTS public.user_gamification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_points INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 1,
  last_activity_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_user_gamification_user_id ON public.user_gamification(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gamification_points ON public.user_gamification(total_points DESC);

-- Table des badges utilisateur
CREATE TABLE IF NOT EXISTS public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  badge_type VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_type)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_type ON public.user_badges(badge_type);

-- Table des événements de gamification (historique)
CREATE TABLE IF NOT EXISTS public.gamification_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL, -- 'points_earned', 'badge_unlocked', 'level_up', etc.
  points INTEGER DEFAULT 0,
  reason TEXT,
  badge_type VARCHAR(50),
  total_points INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_gamification_events_user_id ON public.gamification_events(user_id);
CREATE INDEX IF NOT EXISTS idx_gamification_events_created_at ON public.gamification_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gamification_events_type ON public.gamification_events(event_type);

-- Table des challenges
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'special'
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  target INTEGER NOT NULL,
  reward JSONB NOT NULL, -- { points: number, badge?: string }
  participants INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_challenges_dates ON public.challenges(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_challenges_type ON public.challenges(type);

-- Table de participation aux challenges
CREATE TABLE IF NOT EXISTS public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  progress INTEGER NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge ON public.challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user ON public.challenge_participants(user_id);

-- RLS Policies
ALTER TABLE public.user_gamification ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gamification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own gamification data
CREATE POLICY "Users can view own gamification" ON public.user_gamification
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own badges" ON public.user_badges
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own events" ON public.gamification_events
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Challenges are public (read-only for users)
CREATE POLICY "Challenges are public" ON public.challenges
  FOR SELECT USING (true);

CREATE POLICY "Users can view own challenge participation" ON public.challenge_participants
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Service role can manage all (backend)
CREATE POLICY "Service role can manage gamification" ON public.user_gamification
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage badges" ON public.user_badges
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage events" ON public.gamification_events
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage challenges" ON public.challenges
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage participants" ON public.challenge_participants
  FOR ALL USING (auth.role() = 'service_role');

