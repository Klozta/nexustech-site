-- Migration: Tables pour système de chatbot IA
-- Conversations, messages, historique

-- Table des conversations
CREATE TABLE IF NOT EXISTS public.chatbot_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(255) NOT NULL, -- ID de session (cookie ou user_id)
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'resolved', 'escalated'
  context JSONB, -- Contexte utilisateur (dernière commande, produit consulté, etc.)
  metadata JSONB, -- Métadonnées (raison escalade, etc.)
  message_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_chatbot_conversations_session ON public.chatbot_conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_conversations_user ON public.chatbot_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_conversations_status ON public.chatbot_conversations(status);
CREATE INDEX IF NOT EXISTS idx_chatbot_conversations_updated ON public.chatbot_conversations(updated_at DESC);

-- Table des messages
CREATE TABLE IF NOT EXISTS public.chatbot_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.chatbot_conversations(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL, -- 'user', 'assistant', 'system'
  content TEXT NOT NULL,
  metadata JSONB, -- Métadonnées (intent, productId, orderId, confidence, etc.)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_chatbot_messages_conversation ON public.chatbot_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_messages_created ON public.chatbot_messages(created_at DESC);

-- Table de base de connaissances FAQ (optionnelle)
CREATE TABLE IF NOT EXISTS public.chatbot_knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category VARCHAR(50), -- 'orders', 'products', 'shipping', 'returns', 'general'
  tags TEXT[], -- Tags pour recherche
  priority INTEGER DEFAULT 0, -- Priorité d'affichage
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour recherche
CREATE INDEX IF NOT EXISTS idx_chatbot_kb_category ON public.chatbot_knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_chatbot_kb_active ON public.chatbot_knowledge_base(is_active);
CREATE INDEX IF NOT EXISTS idx_chatbot_kb_tags ON public.chatbot_knowledge_base USING GIN(tags);

-- Table des statistiques chatbot (analytics)
CREATE TABLE IF NOT EXISTS public.chatbot_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_conversations INTEGER DEFAULT 0,
  total_messages INTEGER DEFAULT 0,
  resolved_by_bot INTEGER DEFAULT 0,
  escalated_to_human INTEGER DEFAULT 0,
  avg_response_time_ms INTEGER,
  most_common_intents JSONB, -- { "order_status": 45, "shipping": 30, ... }
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(date)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_chatbot_stats_date ON public.chatbot_stats(date DESC);

-- RLS Policies
ALTER TABLE public.chatbot_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_stats ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own conversations
CREATE POLICY "Users can view own conversations" ON public.chatbot_conversations
  FOR SELECT USING (auth.uid() = user_id OR session_id = current_setting('app.session_id', true));

CREATE POLICY "Users can view own messages" ON public.chatbot_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chatbot_conversations
      WHERE id = conversation_id
      AND (user_id = auth.uid() OR session_id = current_setting('app.session_id', true))
    )
  );

-- Policy: Knowledge base is public (read-only)
CREATE POLICY "Knowledge base is public" ON public.chatbot_knowledge_base
  FOR SELECT USING (is_active = TRUE);

-- Policy: Stats are admin-only
CREATE POLICY "Stats are admin-only" ON public.chatbot_stats
  FOR SELECT USING (auth.role() = 'service_role');

-- Policy: Service role can manage all
CREATE POLICY "Service role can manage conversations" ON public.chatbot_conversations
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage messages" ON public.chatbot_messages
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage knowledge base" ON public.chatbot_knowledge_base
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage stats" ON public.chatbot_stats
  FOR ALL USING (auth.role() = 'service_role');

