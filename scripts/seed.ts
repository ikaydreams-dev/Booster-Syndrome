import { faker } from '@faker-js/faker';

interface SeedData {
  users: number;
  events: number;
  organizations: number;
}

async function seedDatabase(config: SeedData) {
  console.log('🌱 Seeding database...');

  console.log(`👥 Creating ${config.users} users...`);
  const users = [];
  for (let i = 0; i < config.users; i++) {
    users.push({
      email: faker.internet.email(),
      username: faker.internet.userName(),
      firstName: faker.person.firstName(),
      lastName: faker.person.lastName(),
      password: 'hashed_password_123',
      isActive: true,
    });
  }

  console.log(`📊 Creating ${config.events} events...`);
  const events = [];
  for (let i = 0; i < config.events; i++) {
    events.push({
      userId: faker.string.uuid(),
      eventType: faker.helpers.arrayElement(['click', 'view', 'purchase', 'signup']),
      eventName: faker.lorem.word(),
      properties: {
        source: faker.helpers.arrayElement(['web', 'mobile', 'api']),
        value: faker.number.int({ min: 1, max: 1000 }),
      },
      createdAt: faker.date.recent({ days: 30 }),
    });
  }

  console.log(`🏢 Creating ${config.organizations} organizations...`);
  const organizations = [];
  for (let i = 0; i < config.organizations; i++) {
    organizations.push({
      name: faker.company.name(),
      slug: faker.helpers.slugify(faker.company.name()).toLowerCase(),
      type: faker.helpers.arrayElement(['company', 'department', 'team']),
      settings: {
        timezone: faker.location.timeZone(),
        locale: 'en-US',
      },
    });
  }

  console.log('✅ Database seeding complete!');
  console.log(`   Users: ${users.length}`);
  console.log(`   Events: ${events.length}`);
  console.log(`   Organizations: ${organizations.length}`);
}

seedDatabase({
  users: 100,
  events: 1000,
  organizations: 20,
}).catch(console.error);
