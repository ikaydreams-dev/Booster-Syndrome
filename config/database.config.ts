export const databaseConfig = {
  postgres: {
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    database: process.env.POSTGRES_DB || 'booster',
    username: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD || 'password',
    pool: {
      min: 2,
      max: 10,
    },
    ssl: process.env.NODE_ENV === 'production',
  },

  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/booster',
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
    },
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0'),
    maxRetriesPerRequest: 3,
  },

  elasticsearch: {
    node: process.env.ELASTICSEARCH_URL || 'http://localhost:9200',
    auth: {
      username: process.env.ELASTICSEARCH_USER || 'elastic',
      password: process.env.ELASTICSEARCH_PASSWORD || 'password',
    },
  },
};

export const cacheConfig = {
  ttl: parseInt(process.env.CACHE_TTL || '3600'),
  maxKeys: parseInt(process.env.CACHE_MAX_KEYS || '10000'),
  checkPeriod: 600,
};

export const sessionConfig = {
  secret: process.env.SESSION_SECRET || 'super-secret-session-key',
  ttl: parseInt(process.env.SESSION_TTL || '86400'),
  cookieName: 'session_id',
  secure: process.env.NODE_ENV === 'production',
};
