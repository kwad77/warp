// SPEC §3 — closed error-code set and response envelope.
export const ERROR_STATUS = {
  'request/invalid': 400,
  'auth/missing': 401,
  'auth/expired': 401,
  'auth/invalid': 401,
  'auth/refresh_reused': 403,
  'account/suspended': 403,
  'resource/not_found': 404,
  'checkin/duplicate': 409,
  'auth/email_code_used': 409,
  'checkin/nonce_expired': 410,
  'checkin/rejected': 422,
  'photo/rejected': 422,
  'poi/outside_pin_adjust': 422,
  'rate/limited': 429,
  'internal/error': 500,
  'service/unavailable': 503,
} as const;

export type ErrorCode = keyof typeof ERROR_STATUS;

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly details: Record<string, unknown> | undefined;
  readonly statusOverride: number | undefined;

  constructor(
    code: ErrorCode,
    message: string,
    details?: Record<string, unknown>,
    statusOverride?: number,
  ) {
    super(message);
    this.code = code;
    this.details = details;
    this.statusOverride = statusOverride;
  }

  get status(): number {
    return this.statusOverride ?? ERROR_STATUS[this.code];
  }

  toBody(): { error: { code: ErrorCode; message: string; details?: Record<string, unknown> } } {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(this.details !== undefined ? { details: this.details } : {}),
      },
    };
  }
}

/** SPEC §4: not-yet-implemented provider auth returns 501 with service/unavailable. */
export function notImplemented(what: string): AppError {
  return new AppError('service/unavailable', `${what} is not implemented yet`, undefined, 501);
}
