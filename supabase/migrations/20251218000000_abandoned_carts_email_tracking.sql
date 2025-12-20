-- Migration: Ajout tracking emails paniers abandonnés (24h, 48h)
-- Permet de suivre si le premier email (24h) et le second email (48h) ont été envoyés

-- Ajouter colonnes pour tracking emails
ALTER TABLE abandoned_carts
ADD COLUMN IF NOT EXISTS first_email_sent_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS second_email_sent_at TIMESTAMPTZ;

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_first_email
ON abandoned_carts(first_email_sent_at)
WHERE first_email_sent_at IS NULL AND recovered = false;

CREATE INDEX IF NOT EXISTS idx_abandoned_carts_second_email
ON abandoned_carts(second_email_sent_at)
WHERE second_email_sent_at IS NULL AND recovered = false AND email_sent = true;

-- Commentaires
COMMENT ON COLUMN abandoned_carts.first_email_sent_at IS 'Date d''envoi du premier email (24h après abandon)';
COMMENT ON COLUMN abandoned_carts.second_email_sent_at IS 'Date d''envoi du second email de rappel (48h après abandon)';


