import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),

  DATABASE_URL: z.string(),
  REDIS_URL: z.string(),

  JWT_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES: z.string().default('15m'),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_REFRESH_EXPIRES: z.string().default('30d'),

  LIVEKIT_URL: z.string(),
  LIVEKIT_API_KEY: z.string(),
  LIVEKIT_API_SECRET: z.string(),

  MQTT_URL: z.string(),
  MQTT_USERNAME: z.string(),
  MQTT_PASSWORD: z.string(),

  PTT_MAX_DURATION_SECONDS: z.coerce.number().default(60),
  PTT_COOLDOWN_MS: z.coerce.number().default(500),

  RATE_LIMIT_MAX: z.coerce.number().default(100),
  RATE_LIMIT_WINDOW: z.coerce.number().default(60000),

  CORS_ORIGIN: z.string().default('http://localhost:5173'),
});

export type Env = z.infer<typeof envSchema>;

let config: Env;

try {
  config = envSchema.parse(process.env);
} catch (err) {
  if (err instanceof z.ZodError) {
    const missing = err.issues.map((i) => i.path.join('.')).join(', ');
    console.error(`Environment validation failed: ${missing}`);
    process.exit(1);
  }
  throw err;
}

export { config };
