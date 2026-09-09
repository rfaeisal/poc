import { FastifyRequest, FastifyReply } from 'fastify';

export function authorize(...roles: string[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const userRole = request.user.role;
    if (!roles.includes(userRole)) {
      reply.code(403).send({ error: 'Forbidden' });
    }
  };
}
