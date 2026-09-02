CREATE OR REPLACE FUNCTION goodang.deduct_stock(
  p_sku_code        TEXT,
  p_outlet_code     TEXT,
  p_qty             NUMERIC(15,2),
  p_idempotency_key TEXT
)
RETURNS TABLE(
  outcome         TEXT,
  remaining_qty   NUMERIC(15,2),
  error_code      TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = goodang, public
AS $$
DECLARE
  v_current      NUMERIC(15,2);
  v_remaining    NUMERIC(15,2);
  v_already_done BOOLEAN;
BEGIN
  -- Idempotency check via audit log
  SELECT EXISTS(
    SELECT 1 FROM goodang.audit_log
    WHERE event = 'STOCK_DEDUCTED'
      AND payload->>'idempotency_key' = p_idempotency_key
  ) INTO v_already_done;

  IF v_already_done THEN
    RETURN QUERY SELECT 'STOCK_ALREADY_DEDUCTED'::TEXT, NULL::NUMERIC, NULL::TEXT;
    RETURN;
  END IF;

  -- Atomic deduct dengan row lock
  SELECT quantity INTO v_current
  FROM goodang.stock
  WHERE sku_code = p_sku_code AND outlet_code = p_outlet_code
  FOR UPDATE;

  IF v_current IS NULL THEN
    RETURN QUERY SELECT 'STOCK_UNAVAILABLE'::TEXT, NULL::NUMERIC, NULL::TEXT;
    RETURN;
  END IF;

  IF v_current < p_qty THEN
    RETURN QUERY SELECT 'INSUFFICIENT_STOCK'::TEXT, v_current, NULL::TEXT;
    RETURN;
  END IF;

  v_remaining := v_current - p_qty;

  UPDATE goodang.stock
  SET quantity = v_remaining, version = version + 1, updated_at = NOW()
  WHERE sku_code = p_sku_code AND outlet_code = p_outlet_code;

  -- Audit
  INSERT INTO goodang.audit_log (event, actor, payload, created_at)
  VALUES (
    'STOCK_DEDUCTED',
    current_setting('app.actor', true),
    jsonb_build_object(
      'sku_code', p_sku_code,
      'outlet_code', p_outlet_code,
      'qty', p_qty,
      'remaining', v_remaining,
      'idempotency_key', p_idempotency_key
    ),
    NOW()
  );

  RETURN QUERY SELECT 'STOCK_DEDUCTED'::TEXT, v_remaining, NULL::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION goodang.deduct_stock(TEXT, TEXT, NUMERIC, TEXT) TO service_role;
```
