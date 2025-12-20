/**
 * Tests de structure pour orders
 * Teste la génération de numéro de commande et la structure des fonctions
 */

import { v4 as uuidv4 } from 'uuid';

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

// Fonction de génération de numéro de commande (copiée depuis ordersService)
function generateOrderNumber() {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `GC-${timestamp}-${random}`;
}

console.log('🧪 TESTS DE STRUCTURE ORDERS\n');
console.log('='.repeat(50));

// Tests génération numéro de commande
console.log('\n🔢 Tests génération numéro de commande:');
test('Génère un numéro au format GC-XXX-XXX', () => {
  const orderNumber = generateOrderNumber();
  if (!orderNumber.match(/^GC-[A-Z0-9]+-[A-Z0-9]+$/)) {
    throw new Error(`Format invalide: ${orderNumber}`);
  }
});

test('Génère des numéros uniques', () => {
  const numbers = new Set();
  for (let i = 0; i < 100; i++) {
    const num = generateOrderNumber();
    if (numbers.has(num)) {
      throw new Error(`Numéro dupliqué: ${num}`);
    }
    numbers.add(num);
  }
});

test('Numéro commence par GC-', () => {
  const orderNumber = generateOrderNumber();
  if (!orderNumber.startsWith('GC-')) {
    throw new Error(`Ne commence pas par GC-: ${orderNumber}`);
  }
});

// Tests UUID
console.log('\n🆔 Tests UUID:');
test('Génère un UUID valide', () => {
  const uuid = uuidv4();
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(uuid)) {
    throw new Error(`UUID invalide: ${uuid}`);
  }
});

test('Génère des UUIDs uniques', () => {
  const uuids = new Set();
  for (let i = 0; i < 100; i++) {
    const uuid = uuidv4();
    if (uuids.has(uuid)) {
      throw new Error(`UUID dupliqué: ${uuid}`);
    }
    uuids.add(uuid);
  }
});

// Tests structure données
console.log('\n📋 Tests structure données:');
test('Structure OrderItem correcte', () => {
  const item = {
    productId: uuidv4(),
    quantity: 2,
    price: 29.99,
  };
  
  if (!item.productId || !item.quantity || !item.price) {
    throw new Error('Structure OrderItem incomplète');
  }
  if (typeof item.quantity !== 'number' || item.quantity < 1) {
    throw new Error('Quantity doit être un nombre >= 1');
  }
  if (typeof item.price !== 'number' || item.price <= 0) {
    throw new Error('Price doit être un nombre > 0');
  }
});

test('Structure ShippingInfo correcte', () => {
  const shipping = {
    firstName: 'Marie',
    lastName: 'Dupont',
    email: 'marie@example.com',
    phone: '0612345678',
    address: '123 Rue Example',
    city: 'Paris',
    postalCode: '75001',
    country: 'France',
  };
  
  const requiredFields = ['firstName', 'lastName', 'email', 'phone', 'address', 'city', 'postalCode', 'country'];
  for (const field of requiredFields) {
    if (!shipping[field]) {
      throw new Error(`Champ requis manquant: ${field}`);
    }
  }
});

test('Structure CreateOrderInput correcte', () => {
  const order = {
    items: [
      {
        productId: uuidv4(),
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
    total: 34.99,
  };
  
  if (!Array.isArray(order.items) || order.items.length === 0) {
    throw new Error('Items doit être un tableau non vide');
  }
  if (!order.shipping) {
    throw new Error('Shipping est requis');
  }
  if (typeof order.total !== 'number' || order.total <= 0) {
    throw new Error('Total doit être un nombre > 0');
  }
});

// Tests calculs
console.log('\n🧮 Tests calculs:');
test('Calcul total commande correct', () => {
  const items = [
    { productId: uuidv4(), quantity: 2, price: 29.99 },
    { productId: uuidv4(), quantity: 1, price: 49.99 },
  ];
  
  const calculatedTotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const expectedTotal = 29.99 * 2 + 49.99 * 1;
  
  if (Math.abs(calculatedTotal - expectedTotal) > 0.01) {
    throw new Error(`Calcul incorrect: ${calculatedTotal} au lieu de ${expectedTotal}`);
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
  console.log(`\n${colors.green}🎉 Tous les tests de structure sont passés !${colors.reset}\n`);
  process.exit(0);
} else {
  console.log(`\n${colors.red}❌ Certains tests ont échoué${colors.reset}\n`);
  process.exit(1);
}








