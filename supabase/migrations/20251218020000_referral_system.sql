-- Migration: Système de parrainage (codes de parrainage, tracking, récompenses)
-- Permet aux utilisateurs de parrainer d'autres utilisateurs et de gagner des récompenses

-- ============================================
-- TABLE REFERRAL_CODES
-- ============================================
-- Stocke les codes de parrainage uniques pour chaque utilisateur
CREATE TABLE IF NOT EXISTS referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code TEXT UNIQUE NOT NULL, -- Code unique (ex: "MARIE2024")
  is_active BOOLEAN NOT NULL DEFAULT true,
  total_referrals INTEGER NOT NULL DEFAULT 0, -- Nombre total de parrainages réussis
  total_rewards_earned DECIMAL(10,2) NOT NULL DEFAULT 0, -- Total des récompenses gagnées
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ============================================
-- TABLE REFERRAL_TRACKING
-- ============================================
-- Historique des parrainages (qui a parrainé qui, quand, récompenses)
CREATE TABLE IF NOT EXISTS referral_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Celui qui parraine
  referred_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Celui qui est parrainé
  referral_code_id UUID NOT NULL REFERENCES referral_codes(id) ON DELETE CASCADE,
  referral_code TEXT NOT NULL, -- Code utilisé (pour historique)
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded', 'cancelled')),
  -- Récompenses
  referrer_reward_type TEXT CHECK (referrer_reward_type IN ('points', 'discount', 'cashback')),
  referrer_reward_amount DECIMAL(10,2) DEFAULT 0,
  referred_reward_type TEXT CHECK (referred_reward_type IN ('points', 'discount', 'cashback')),
  referred_reward_amount DECIMAL(10,2) DEFAULT 0,
  -- Tracking
  first_order_id UUID REFERENCES orders(id) ON DELETE SET NULL, -- Première commande du parrainé
  reward_given_at TIMESTAMP WITH TIME ZONE, -- Quand la récompense a été donnée
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(referred_id) -- Un utilisateur ne peut être parrainé qu'une fois
);

-- ============================================
-- INDEXES pour performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_referral_codes_user_id ON referral_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_referral_tracking_referrer_id ON referral_tracking(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_referred_id ON referral_tracking(referred_id);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_code_id ON referral_tracking(referral_code_id);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_status ON referral_tracking(status);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_created_at ON referral_tracking(created_at DESC);

-- ============================================
-- FUNCTION: Générer un code de parrainage unique
-- ============================================
CREATE OR REPLACE FUNCTION generate_referral_code(user_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_code TEXT;
  final_code TEXT;
  counter INTEGER := 0;
  year_suffix TEXT;
BEGIN
  -- Nettoyer le nom (majuscules, supprimer espaces/caractères spéciaux)
  base_code := UPPER(REGEXP_REPLACE(COALESCE(user_name, 'USER'), '[^A-Z0-9]', '', 'g'));
  -- Limiter à 6 caractères pour laisser de la place au suffixe
  base_code := SUBSTRING(base_code, 1, 6);
  -- Ajouter année si nécessaire
  year_suffix := TO_CHAR(NOW(), 'YY');
  IF LENGTH(base_code) < 3 THEN
    base_code := base_code || year_suffix;
  ELSE
    base_code := base_code || year_suffix;
  END IF;
  
  final_code := base_code;
  
  -- Vérifier unicité et ajouter un suffixe si nécessaire
  WHILE EXISTS (SELECT 1 FROM referral_codes WHERE code = final_code) LOOP
    counter := counter + 1;
    final_code := base_code || LPAD(counter::TEXT, 3, '0');
    -- Limite de sécurité
    IF counter > 999 THEN
      final_code := base_code || TO_CHAR(NOW(), 'MMDD') || counter::TEXT;
      EXIT;
    END IF;
  END LOOP;
  
  RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Mettre à jour le compteur de parrainages
-- ============================================
CREATE OR REPLACE FUNCTION update_referral_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Mettre à jour le compteur quand un parrainage est complété
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE referral_codes
    SET
      total_referrals = total_referrals + 1,
      updated_at = NOW()
    WHERE id = NEW.referral_code_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour le compteur
CREATE TRIGGER trigger_update_referral_count
  AFTER UPDATE OF status ON referral_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_referral_count();

-- Commentaires
COMMENT ON TABLE referral_codes IS 'Codes de parrainage uniques par utilisateur';
COMMENT ON TABLE referral_tracking IS 'Historique des parrainages et récompenses';
COMMENT ON COLUMN referral_codes.code IS 'Code unique de parrainage (ex: MARIE2024)';
COMMENT ON COLUMN referral_tracking.status IS 'pending: inscription, completed: première commande, rewarded: récompense donnée';
COMMENT ON COLUMN referral_tracking.referrer_reward_amount IS 'Montant de la récompense pour le parrain (points ou euros)';
COMMENT ON COLUMN referral_tracking.referred_reward_amount IS 'Montant de la récompense pour le parrainé (points ou euros)';
