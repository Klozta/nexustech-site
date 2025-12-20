/**
 * Test de validation pour orders - Sans dépendances externes
 * Utilise directement Zod pour tester les schémas
 */

import { createOrderSchema, orderItemSchema, shippingInfoSchema } from './src/validations/schemas.js';

const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m',
};

let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`${colors.green}✅${colors.reset} ${name}`);
    testsPassed++;
  } catch (error) {
    console.log(`${colors.red}❌${colors.reset} ${name}`);
    console.log(`   ${colors.red}Erreur:${colors.reset} ${error.message}`);
    testsFailed++;
  }
}

console.log('🧪 TESTS DE VALIDATION ORDERS\n');
console.log('='.repeat(50));

// Tests orderItemSchema
console.log('\n📦 Tests orderItemSchema:');
test('Item valide avec UUID, quantity=2, price=29.99', () => {
  const validItem = {
    productId: '123e4567-e89b-12d3-a456-426614174000',
    quantity: 2,
    price: 29.99,
  };
  const result = orderItemSchema.safeParse(validItem);
  if (!result.success) {
    throw new Error('Devrait être valide');
  }
});

test('Item invalide: quantity=0 (doit être >= 1)', () => {
  const invalidItem = {
    productId: '123e4567-e89b-12d3-a456-426614174000',
    quantity: 0,
    price: 29.99,
  };
  const result = orderItemSchema.safeParse(invalidItem);
  if (result.success) {
    throw new Error('Devrait être invalide (quantity < 1)');
  }
});

test('Item invalide: price négatif', () => {
  const invalidItem = {
    productId: '123e4567-e89b-12d3-a456-426614174000',
    quantity: 1,
    price: -10,
  };
  const result = orderItemSchema.safeParse(invalidItem);
  if (result.success) {
    throw new Error('Devrait être invalide (price négatif)');
  }
});

test('Item invalide: UUID invalide', () => {
  const invalidItem = {
    productId: 'not-a-uuid',
    quantity: 1,
    price: 29.99,
  };
  const result = orderItemSchema.safeParse(invalidItem);
  if (result.success) {
    throw new Error('Devrait être invalide (UUID invalide)');
  }
});

// Tests shippingInfoSchema
console.log('\n📮 Tests shippingInfoSchema:');
test('Shipping valide avec tous les champs', () => {
  const validShipping = {
    firstName: 'Marie',
    lastName: 'Dupont',
    email: 'marie@example.com',
    phone: '0612345678',
    address: '123 Rue Example',
    city: 'Paris',
    postalCode: '75001',
    country: 'France',
  };
  const result = shippingInfoSchema.safeParse(validShipping);
  if (!result.success) {
    throw new Error('Devrait être valide');
  }
});

test('Shipping invalide: email invalide', () => {
  const invalidShipping = {
    firstName: 'Marie',
    lastName: 'Dupont',
    email: 'email-invalide',
    phone: '0612345678',
    address: '123 Rue Example',
    city: 'Paris',
    postalCode: '75001',
    country: 'France',
  };
  const result = shippingInfoSchema.safeParse(invalidShipping);
  if (result.success) {
    throw new Error('Devrait être invalide (email invalide)');
  }
});

test('Shipping invalide: code postal invalide (trop court)', () => {
  const invalidShipping = {
    firstName: 'Marie',
    lastName: 'Dupont',
    email: 'marie@example.com',
    phone: '0612345678',
    address: '123 Rue Example',
    city: 'Paris',
    postalCode: '123',
    country: 'France',
  };
  const result = shippingInfoSchema.safeParse(invalidShipping);
  if (result.success) {
    throw new Error('Devrait être invalide (code postal invalide)');
  }
});

test('Shipping invalide: prénom trop court', () => {
  const invalidShipping = {
    firstName: 'M',
    lastName: 'Dupont',
    email: 'marie@example.com',
    phone: '0612345678',
    address: '123 Rue Example',
    city: 'Paris',
    postalCode: '75001',
    country: 'France',
  };
  const result = shippingInfoSchema.safeParse(invalidShipping);
  if (result.success) {
    throw new Error('Devrait être invalide (prénom trop court)');
  }
});

// Tests createOrderSchema
console.log('\n🛒 Tests createOrderSchema:');
test('Commande complète valide', () => {
  const validOrder = {
    items: [
      {
        productId: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 2,
        price: 29.99,
      },
    ],
    shipping: {
      firstName: 'Marie',
      lastName: 'Dupont',
      email: 'marie@example.com',
      phone: '0612345678',
      address: '123 Rue Example',
      city: 'Paris',
      postalCode: '75001',
      country: 'France',
    },
    total: 64.98,
  };
  const result = createOrderSchema.safeParse(validOrder);
  if (!result.success) {
    throw new Error('Devrait être valide');
  }
});

test('Commande invalide: items vide', () => {
  const invalidOrder = {
    items: [],
    shipping: {
      firstName: 'Marie',
      lastName: 'Dupont',
      email: 'marie@example.com',
      phone: '0612345678',
      address: '123 Rue Example',
      city: 'Paris',
      postalCode: '75001',
      country: 'France',
    },
    total: 0,
  };
  const result = createOrderSchema.safeParse(invalidOrder);
  if (result.success) {
    throw new Error('Devrait être invalide (items vide)');
  }
});

test('Commande invalide: total négatif', () => {
  const invalidOrder = {
    items: [
      {
        productId: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 1,
        price: 29.99,
      },
    ],
    shipping: {
      firstName: 'Marie',
      lastName: 'Dupont',
      email: 'marie@example.com',
      phone: '0612345678',
      address: '123 Rue Example',
      city: 'Paris',
      postalCode: '75001',
      country: 'France',
    },
    total: -10,
  };
  const result = createOrderSchema.safeParse(invalidOrder);
  if (result.success) {
    throw new Error('Devrait être invalide (total négatif)');
  }
});

test('Commande avec plusieurs items valides', () => {
  const validOrder = {
    items: [
      {
        productId: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 2,
        price: 29.99,
      },
      {
        productId: '223e4567-e89b-12d3-a456-426614174001',
        quantity: 1,
        price: 49.99,
      },
    ],
    shipping: {
      firstName: 'Marie',
      lastName: 'Dupont',
      email: 'marie@example.com',
      phone: '0612345678',
      address: '123 Rue Example',
      city: 'Paris',
      postalCode: '75001',
      country: 'France',
    },
    total: 109.97,
  };
  const result = createOrderSchema.safeParse(validOrder);
  if (!result.success) {
    throw new Error('Devrait être valide avec plusieurs items');
  }
});

// Résumé
console.log('\n' + '='.repeat(50));
console.log('\n📊 RÉSUMÉ DES TESTS:');
console.log(`${colors.green}✅ Tests réussis: ${testsPassed}${colors.reset}`);
if (testsFailed > 0) {
  console.log(`${colors.red}❌ Tests échoués: ${testsFailed}${colors.reset}`);
} else {
  console.log(`${colors.green}✅ Aucun test échoué${colors.reset}`);
}
console.log(`Total: ${testsPassed + testsFailed} tests`);

if (testsFailed === 0) {
  console.log(`\n${colors.green}🎉 Tous les tests de validation sont passés !${colors.reset}\n`);
  process.exit(0);
} else {
  console.log(`\n${colors.red}❌ Certains tests ont échoué${colors.reset}\n`);
  process.exit(1);
}








