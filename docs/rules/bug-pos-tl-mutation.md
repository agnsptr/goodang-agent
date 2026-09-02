# Rule: pos_transaction_log Append-Only — UPDATE/DELETE Dilarang

**Severity:** P0
**Konteks:** Supabase schema, Transaction Service, ledger integrity
**Referensi:** `docs/0` §10.1, `docs/12` ADR-005, `docs/14` §7

## Don't

`pos_transaction_log` adalah ledger transaksi final. **TIDAK BOLEH** di-UPDATE atau di-DELETE, bahkan oleh admin atau service_role. Correction mechanism: INSERT compensating entry dengan `line_amount` negatif.

## Do

- `REVOKE UPDATE, DELETE ON pos_transaction_log FROM authenticated, anon, service_role`
- Trigger `FORBID_ROW_MODIFICATION` raise exception kalau ada UPDATE/DELETE attempt
- Correction: INSERT reversal entry dengan `remarks='REVERSAL:<original_transaction_id>'`
- Write hanya via `service_role` dari Transaction Service (Temporal activity)

## Contoh SALAH

```sql
-- DILARANG
UPDATE goodang.pos_transaction_log
SET qty = 5
WHERE transaction_id = 'TXN-001';

-- DILARANG
DELETE FROM goodang.pos_transaction_log
WHERE transaction_id = 'TXN-001';
```

```python
# DILARANG
supabase.table("pos_transaction_log").update({"qty": 5}).eq("transaction_id", "TXN-001").execute()
```

## Contoh BENAR

```sql
-- BENAR: insert reversal entry
INSERT INTO goodang.pos_transaction_log (
  transaction_id, transaction_date, outlet_code, member_id, member_name,
  payment_method, sku_code, product_name, uom, qty, cooked_qty,
  selling_price, service_fee, line_amount, remarks, created_by
) VALUES (
  'TXN-001-REV', NOW(), 'OUT01', 'M001', 'Budi',
  'CASH', 'SKU001', 'Buku Tulis', 'pcs', -10, 0,
  5000, 0, -50000, 'REVERSAL:TXN-001', 'system'
);
```

```python
# BENAR: insert reversal via Transaction Service
await transaction_service.create_reversal(
    original_transaction_id="TXN-001",
    reason="qty correction",
)
```

## Deteksi

- DB trigger `FORBID_ROW_MODIFICATION` (hard gate di DB level)
- CI secret scan untuk `UPDATE.*pos_transaction_log` / `DELETE.*pos_transaction_log`
- CodeRabbit — review SQL statements
