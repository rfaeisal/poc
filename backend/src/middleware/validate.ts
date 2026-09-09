import { FastifyRequest, FastifyReply } from 'fastify';
import { ZodSchema, ZodError } from 'zod';

export function validate(schema: ZodSchema) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      request.body = schema.parse(request.body);
    } catch (err) {
      if (err instanceof ZodError) {
        reply.code(400).send({
          error: 'Validation error',
          details: err.issues.map((i) => ({
            field: i.path.join('.'),
            message: i.message,
          })),
        });
      }
    }
  };
}

export function validateQuery(schema: ZodSchema) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      request.query = schema.parse(request.query);
    } catch (err) {
      if (err instanceof ZodError) {
        reply.code(400).send({
          error: 'Validation error',
          details: err.issues.map((i) => ({
            field: i.path.join('.'),
            message: i.message,
          })),
        });
      }
    }
  };
}
