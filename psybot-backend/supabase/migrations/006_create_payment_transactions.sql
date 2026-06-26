-- 006_create_payment_transactions.sql
-- MOVED before consultations to resolve FK dependency
CREATE TABLE public.payment_transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user         UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  amount          INTEGER NOT NULL CHECK (amount >= 0),
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                    'pending', 'success', 'failed', 'expired', 'refunded', 'cancelled'
                  )),
  order_id        TEXT NOT NULL UNIQUE,
  gateway_ref     TEXT,
  payment_method  TEXT CHECK (payment_method IN (
                    'qris', 'gopay', 'ovo', 'bca_va', 'bni_va', 'mandiri_va',
                    'bri_va', 'permata_va', 'dana', 'linkaja', 'credit_card'
                  )),
  snap_token      TEXT,
  snap_redirect_url TEXT,
  midtrans_payload JSONB,
  expired_at      TIMESTAMPTZ,
  paid_at         TIMESTAMPTZ,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_id_user ON public.payment_transactions(id_user);
CREATE INDEX idx_payment_status ON public.payment_transactions(status);
CREATE INDEX idx_payment_order_id ON public.payment_transactions(order_id);
CREATE INDEX idx_payment_timestamp ON public.payment_transactions(timestamp DESC);

CREATE TRIGGER payment_transactions_updated_at
  BEFORE UPDATE ON public.payment_transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.payment_transactions IS 'Riwayat transaksi Midtrans. midtrans_payload disimpan untuk keperluan audit dan reconciliation.';
