-- Migration: Email Preferences
-- Permet aux utilisateurs de gérer leurs préférences d'emails

-- Table email_preferences
CREATE TABLE IF NOT EXISTS public.email_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Emails transactionnels (toujours activés par défaut, mais peuvent être désactivés)
  order_confirmation BOOLEAN DEFAULT true,
  order_shipped BOOLEAN DEFAULT true,
  order_delivered BOOLEAN DEFAULT true,
  abandoned_cart BOOLEAN DEFAULT true,

  -- Emails marketing (désactivés par défaut)
  newsletter BOOLEAN DEFAULT false,
  promotions BOOLEAN DEFAULT false,
  product_recommendations BOOLEAN DEFAULT false,
  loyalty_updates BOOLEAN DEFAULT false,

  -- Fréquence d'envoi pour emails marketing
  frequency TEXT DEFAULT 'weekly' CHECK (frequency IN ('immediate', 'daily', 'weekly', 'monthly', 'never')),

  -- Métadonnées
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Un seul profil par utilisateur
  UNIQUE(user_id)
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS email_preferences_user_id_idx ON public.email_preferences(user_id);

-- RLS Policies
ALTER TABLE public.email_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres préférences
CREATE POLICY "Users can view their own email preferences"
  ON public.email_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent créer leurs propres préférences
CREATE POLICY "Users can create their own email preferences"
  ON public.email_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent mettre à jour leurs propres préférences
CREATE POLICY "Users can update their own email preferences"
  ON public.email_preferences
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_email_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_email_preferences_updated_at
  BEFORE UPDATE ON public.email_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_email_preferences_updated_at();

-- Commentaires
COMMENT ON TABLE public.email_preferences IS 'Préférences emails des utilisateurs pour respecter leur choix et améliorer l''engagement';
COMMENT ON COLUMN public.email_preferences.frequency IS 'Fréquence d''envoi pour emails marketing: immediate, daily, weekly, monthly, never';


