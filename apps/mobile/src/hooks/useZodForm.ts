import { useState, useCallback } from 'react';
import { z, ZodSchema } from 'zod';

interface UseZodFormOptions<T extends ZodSchema> {
  schema: T;
  onSubmit: (data: z.infer<T>) => Promise<void>;
}

export function useZodForm<T extends ZodSchema>({ schema, onSubmit }: UseZodFormOptions<T>) {
  const [data, setData] = useState<Partial<z.infer<T>>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const setValue = useCallback((key: keyof z.infer<T>, value: any) => {
    setData((prev) => ({ ...prev, [key]: value }));
    // Clear error when field is modified
    if (errors[key as string]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[key as string];
        return newErrors;
      });
    }
  }, [errors]);

  const handleSubmit = useCallback(async () => {
    setIsSubmitting(true);
    setErrors({});

    try {
      const validated = schema.parse(data);
      await onSubmit(validated);
      return true;
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors: Record<string, string> = {};
        error.errors.forEach((err) => {
          formattedErrors[err.path.join('.')] = err.message;
        });
        setErrors(formattedErrors);
      }
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }, [data, schema, onSubmit]);

  return {
    data,
    errors,
    isSubmitting,
    setValue,
    handleSubmit,
  };
}
