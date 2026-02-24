import { z } from 'zod';

export const UuidSchema = z.string().uuid();
export const EmailSchema = z.string().email();
export const PhoneSchema = z.string().regex(/^\+?[1-9]\d{1,14}$/);
export const MoneySchema = z.number().positive().multipleOf(0.01);

export const TimestampSchema = z.union([
  z.string().datetime(),
  z.date(),
  z.number()
]);

export const PaginationSchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().positive().max(100).default(20),
});

export type Pagination = z.infer<typeof PaginationSchema>;
