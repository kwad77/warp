// SPEC §5.2 — L1 Integrity. Platform verifiers (Play Integrity / App Attest) are M1.4;
// until then: dev tokens outside production, unconditional 'degraded' in production.
export type IntegrityOutcome = 'pass' | 'degraded' | 'fail';

export interface IntegrityVerdict {
  outcome: IntegrityOutcome;
  provider: string;
  detail?: string;
}

export interface IntegrityVerifier {
  verify(integrityToken: string, nonce: string): Promise<IntegrityVerdict>;
}

/** `dev.<pass|degraded|fail>.<nonce>` — anything else (or a nonce mismatch) fails. */
export function devIntegrityVerifier(): IntegrityVerifier {
  return {
    async verify(token, nonce) {
      const match = /^dev\.(pass|degraded|fail)\.(.+)$/.exec(token);
      if (!match || match[2] !== nonce) {
        return { outcome: 'fail', provider: 'dev', detail: 'malformed_or_nonce_mismatch' };
      }
      return { outcome: match[1] as IntegrityOutcome, provider: 'dev' };
    },
  };
}

/** Production placeholder: nothing can attest ⇒ everything is degraded (caps at pending). */
export function degradedIntegrityVerifier(): IntegrityVerifier {
  return {
    async verify() {
      return { outcome: 'degraded', provider: 'none', detail: 'platform_verifiers_pending' };
    },
  };
}

export function createIntegrityVerifier(nodeEnv: string): IntegrityVerifier {
  return nodeEnv === 'production' ? degradedIntegrityVerifier() : devIntegrityVerifier();
}
