import 'dotenv/config';
import { config } from './config';
import { buildApp } from './app';

const app = buildApp();

app.listen({ port: config.PORT, host: config.HOST }, (err, address) => {
  if (err) {
    app.log.error(err);
    process.exit(1);
  }
  app.log.info(`Server listening on ${address}`);
});

const shutdown = async (signal: string) => {
  app.log.info(`${signal} received, shutting down...`);
  await app.close();
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
