-- Asegurar columnas en Grupos_Ahorro
ALTER TABLE "Financiamientos"."Grupos_Ahorro" ADD COLUMN IF NOT EXISTS fecha_primer_pago DATE;

-- Crear tabla de Cuotas para Grupos de Ahorro
CREATE TABLE IF NOT EXISTS "Financiamientos"."Cuotas_Ahorro" (
    "id" UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    "miembro_id" UUID NOT NULL REFERENCES "Financiamientos"."Miembros_Grupo"("id") ON DELETE CASCADE,
    "numero_cuota" INT NOT NULL,
    "monto_esperado" NUMERIC(12,2) NOT NULL,
    "monto_pagado" NUMERIC(12,2) DEFAULT 0,
    "fecha_vencimiento" DATE NOT NULL,
    "pagada" BOOLEAN DEFAULT FALSE,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- RLS (Row Level Security)
ALTER TABLE "Financiamientos"."Cuotas_Ahorro" ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'Cuotas_Ahorro' AND policyname = 'Allow all for authenticated users'
    ) THEN
        CREATE POLICY "Allow all for authenticated users" 
        ON "Financiamientos"."Cuotas_Ahorro" 
        FOR ALL 
        TO authenticated 
        USING (true) 
        WITH CHECK (true);
    END IF;
END $$;
