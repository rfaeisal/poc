import Fastify from 'fastify';
import helmet from '@fastify/helmet';
import prismaPlugin from './plugins/prisma';
import redisPlugin from './plugins/redis';
import authPlugin from './plugins/auth';
import corsPlugin from './plugins/cors';
import rateLimitPlugin from './plugins/rate-limit';
import mqttPlugin from './plugins/mqtt';
import authRoutes from './routes/auth';
import channelRoutes from './routes/channels';
import userRoutes from './routes/users';
import organizationRoutes from './routes/organizations';
import adminRoutes from './routes/admin';
import livekitWebhookRoute from './routes/webhook/livekit';
import echoRoutes from './routes/echo';

export function buildApp() {
  const app = Fastify({
    logger: {
      level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    },
  });

  // Security headers
  app.register(helmet);

  // Plugins
  app.register(corsPlugin);
  app.register(rateLimitPlugin);
  app.register(authPlugin);
  app.register(prismaPlugin);
  app.register(redisPlugin);
  app.register(mqttPlugin);

  // Routes
  app.register(authRoutes);
  app.register(channelRoutes);
  app.register(userRoutes);
  app.register(organizationRoutes);
  app.register(adminRoutes);
  app.register(livekitWebhookRoute);
  app.register(echoRoutes);

  // Health check
  app.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

  // Global error handler
  app.setErrorHandler((error, request, reply) => {
    if (error.validation) {
      reply.code(400).send({
        error: 'Validation error',
        details: error.validation,
      });
      return;
    }

    request.log.error(error);
    reply.code(error.statusCode ?? 500).send({
      error: error.statusCode === 500 ? 'Internal server error' : error.message,
    });
  });

  return app;
}
