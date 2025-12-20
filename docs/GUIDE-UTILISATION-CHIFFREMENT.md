# 🔐 Guide d'Utilisation du Chiffrement

Guide pratique pour utiliser le service de chiffrement dans le projet GirlyCrea.

## 📋 Vue d'ensemble

Le service de chiffrement permet de protéger les données sensibles (téléphones, adresses) conformément aux recommandations RGPD. **Les emails ne sont PAS chiffrés** car nécessaires pour l'authentification et l'envoi d'emails.

## ⚙️ Configuration

### 1. Générer la clé de chiffrement

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Cela génère une clé de 64 caractères hexadécimaux (32 bytes).

### 2. Ajouter dans `.env`

```bash
MASTER_ENCRYPTION_KEY=your-64-hex-characters-key-here
```

⚠️ **IMPORTANT** :
- Stocker la clé dans un gestionnaire de secrets (AWS Secrets Manager, HashiCorp Vault, etc.) en production
- Rotation annuelle recommandée
- Jamais en `.env` commité dans Git

## 🚀 Utilisation

### Chiffrer/Déchiffrer un téléphone

```typescript
import { encryptPhone, decryptPhone } from '../utils/encryptionHelpers.js';

// Chiffrer avant stockage
const phone = "+33612345678";
const encryptedPhone = encryptPhone(phone);
// Stocker encryptedPhone dans la DB

// Déchiffrer à la lecture
const decryptedPhone = decryptPhone(encryptedPhone);
```

### Chiffrer/Déchiffrer une adresse complète

```typescript
import { encryptAddress, decryptAddress } from '../utils/encryptionHelpers.js';

// Chiffrer avant stockage
const address = {
  street: "123 Rue de la Paix",
  city: "Paris",
  postalCode: "75001",
  country: "France"
};
const encryptedAddress = encryptAddress(address);
// Stocker encryptedAddress dans la DB

// Déchiffrer à la lecture
const decrypted = decryptAddress(encryptedAddress);
// Retourne: { street: "123 Rue de la Paix", city: "Paris", ... }
```

### Utilisation directe du service (avancé)

```typescript
import { getEncryptionService } from '../services/encryptionService.js';

const encryptor = getEncryptionService();

// Chiffrer une string
const encrypted = encryptor.encrypt("Donnée sensible");

// Déchiffrer
const decrypted = encryptor.decrypt(encrypted);

// Chiffrer un objet
const encryptedObj = encryptor.encryptObject({
  field1: "value1",
  field2: "value2"
});

// Déchiffrer un objet
const decryptedObj = encryptor.decryptObject(encryptedObj);
```

## 📝 Exemple d'Intégration

### Dans un service utilisateur

```typescript
import { encryptPhone } from '../utils/encryptionHelpers.js';
import { supabase } from '../config/supabase.js';

export async function updateUserPhone(userId: string, phone: string) {
  const encryptedPhone = encryptPhone(phone);

  const { data, error } = await supabase
    .from('users')
    .update({ phone_encrypted: encryptedPhone })
    .eq('id', userId);

  if (error) throw error;
  return data;
}

export async function getUserPhone(userId: string): Promise<string | null> {
  const { data } = await supabase
    .from('users')
    .select('phone_encrypted')
    .eq('id', userId)
    .single();

  if (!data) return null;

  const { decryptPhone } = await import('../utils/encryptionHelpers.js');
  return decryptPhone(data.phone_encrypted);
}
```

### Dans un service de commandes

```typescript
import { encryptAddress, decryptAddress } from '../utils/encryptionHelpers.js';
import { supabase } from '../config/supabase.js';

export async function createOrder(orderData: {
  userId: string;
  shippingAddress: {
    street: string;
    city: string;
    postalCode: string;
    country: string;
  };
  // ... autres champs
}) {
  const encryptedAddress = encryptAddress(orderData.shippingAddress);

  const { data, error } = await supabase
    .from('orders')
    .insert({
      user_id: orderData.userId,
      shipping_address_encrypted: encryptedAddress,
      // ... autres champs
    });

  if (error) throw error;
  return data;
}

export async function getOrderShippingAddress(orderId: string) {
  const { data } = await supabase
    .from('orders')
    .select('shipping_address_encrypted')
    .eq('id', orderId)
    .single();

  if (!data) return null;

  return decryptAddress(data.shipping_address_encrypted);
}
```

## 🗄️ Migration de la Base de Données

Si vous avez déjà des données en clair, voici un script de migration :

```sql
-- Ajouter colonnes pour données chiffrées
ALTER TABLE users ADD COLUMN phone_encrypted TEXT;
ALTER TABLE orders ADD COLUMN shipping_address_encrypted TEXT;

-- Migration script Node.js
import { encryptPhone, encryptAddress } from './utils/encryptionHelpers.js';
import { supabase } from './config/supabase.js';

async function migrateUserPhones() {
  const { data: users } = await supabase
    .from('users')
    .select('id, phone')
    .not('phone', 'is', null);

  for (const user of users || []) {
    try {
      const encrypted = encryptPhone(user.phone);
      await supabase
        .from('users')
        .update({ phone_encrypted: encrypted })
        .eq('id', user.id);
    } catch (error) {
      console.error(`Failed to migrate phone for user ${user.id}`, error);
    }
  }
}
```

## ⚠️ Limitations et Bonnes Pratiques

### Ce qui NE doit PAS être chiffré

- ❌ **Emails** : Nécessaires pour authentification et envoi d'emails
- ❌ **IDs** : Nécessaires pour relations DB et recherche
- ❌ **Timestamps** : Nécessaires pour requêtes temporelles
- ❌ **Montants** : Nécessaires pour calculs et rapports

### Ce qui DOIT être chiffré

- ✅ **Téléphones** : Données sensibles, pas utilisées pour recherche
- ✅ **Adresses complètes** : Données personnelles sensibles
- ✅ **Informations bancaires** : (mais utiliser Stripe pour les paiements)

### Bonnes Pratiques

1. **Chiffrer uniquement à l'écriture** : Ne pas re-chiffrer des données déjà chiffrées
2. **Déchiffrer uniquement à la lecture** : Ne pas stocker les données déchiffrées
3. **Gérer les erreurs** : Si le déchiffrement échoue, retourner null plutôt que de crash
4. **Logging sécurisé** : Ne jamais logger les données déchiffrées
5. **Rotation des clés** : Planifier une rotation annuelle avec migration

## 🔄 Rotation des Clés

Quand il est temps de changer la clé de chiffrement :

1. Générer une nouvelle clé
2. Créer un script de migration qui :
   - Lit toutes les données chiffrées avec l'ancienne clé
   - Re-chiffre avec la nouvelle clé
   - Met à jour la base de données
3. Tester la migration sur un environnement de staging
4. Exécuter en production avec backup préalable
5. Mettre à jour `MASTER_ENCRYPTION_KEY`

## 🧪 Tests

```typescript
import { encryptPhone, decryptPhone } from '../utils/encryptionHelpers.js';

describe('Encryption Helpers', () => {
  it('should encrypt and decrypt phone', () => {
    const phone = "+33612345678";
    const encrypted = encryptPhone(phone);
    expect(encrypted).not.toBe(phone);
    expect(encrypted).toContain(':');

    const decrypted = decryptPhone(encrypted);
    expect(decrypted).toBe(phone);
  });

  it('should handle null values', () => {
    expect(encryptPhone(null)).toBeNull();
    expect(decryptPhone(null)).toBeNull();
  });
});
```

## 📚 Références

- Service de chiffrement : `src/services/encryptionService.ts`
- Helpers : `src/utils/encryptionHelpers.ts`
- Documentation sécurité : `docs/SECURITY-COMPLIANCE-2025.md`

