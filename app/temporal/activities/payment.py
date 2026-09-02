"""Temporal activities — payment. Suffix _activity per docs/0 §4."""

# execute_payment_activity (Class D):
# - INSERT payment with idempotency_key = GOODANG-PAY:{transaction_id}
# - On unique violation → return PAYMENT_ALREADY_PROCESSED (non-retryable, docs/0 §7.7)
