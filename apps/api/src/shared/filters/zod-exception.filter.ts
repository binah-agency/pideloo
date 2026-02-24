import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { ZodError, ZodIssue } from 'zod';
import { fromZodError } from 'zod-validation-error';

@Catch(ZodError)
export class ZodExceptionFilter implements ExceptionFilter {
  catch(exception: ZodError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    
    const validationError = fromZodError(exception, {
      prefix: 'Validation failed',
      includePath: true,
    });

    response.status(HttpStatus.BAD_REQUEST).json({
      statusCode: HttpStatus.BAD_REQUEST,
      message: validationError.message,
      errors: exception.errors.map((err: ZodIssue) => ({
        path: err.path.join('.'),
        message: err.message,
      })),
      timestamp: new Date().toISOString(),
    });
  }
}
