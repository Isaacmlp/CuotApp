-- ============================================================
-- MIGRACIÓN: Módulo de Grupos de Ahorro
-- Ejecutar en Supabase SQL Editor (schema: Financiamientos)
-- ============================================================

-- 1. Tabla de Grupos de Ahorro
CREATE TABLE IF NOT EXISTS "Financiamientos"."Grupos_Ahorro" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    meta_ahorro NUMERIC(12,2) DEFAULT 0,
    tipo_aporte TEXT DEFAULT 'comun' CHECK (tipo_aporte IN ('comun', 'diferente')),
    periodo TEXT DEFAULT 'semanal' CHECK (periodo IN ('semanal', 'quincenal', 'mensual')),
    total_acumulado NUMERIC(12,2) DEFAULT 0,
    creado_por TEXT NOT NULL, -- Nombre de usuario o ID
    fecha_creacion TIMESTAMPTZ DEFAULT NOW(),
    estado TEXT DEFAULT 'activo' CHECK (estado IN ('activo', 'finalizado', 'cancelado')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabla de Miembros del Grupo
CREATE TABLE IF NOT EXISTS "Financiamientos"."Miembros_Grupo" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES "Financiamientos"."Grupos_Ahorro"(id) ON DELETE CASCADE,
    cliente_id UUID NOT NULL REFERENCES "Financiamientos"."Clientes"(id) ON DELETE CASCADE,
    monto_meta_personal NUMERIC(12,2) DEFAULT 0, -- Útil si el tipo_aporte es 'diferente'
    total_aportado NUMERIC(12,2) DEFAULT 0,
    fecha_ingreso TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(grupo_id, cliente_id) -- No permitir duplicados en el mismo grupo
);

-- 3. Tabla de Aportes del Grupo
CREATE TABLE IF NOT EXISTS "Financiamientos"."Aportes_Grupo" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    miembro_id UUID NOT NULL REFERENCES "Financiamientos"."Miembros_Grupo"(id) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    fecha_aporte TIMESTAMPTZ DEFAULT NOW(),
    metodo_pago TEXT DEFAULT 'efectivo',
    referencia TEXT,
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_grupos_creado_por ON "Financiamientos"."Grupos_Ahorro"(creado_por);
CREATE INDEX IF NOT EXISTS idx_miembros_grupo ON "Financiamientos"."Miembros_Grupo"(grupo_id);
CREATE INDEX IF NOT EXISTS idx_miembros_cliente ON "Financiamientos"."Miembros_Grupo"(cliente_id);
CREATE INDEX IF NOT EXISTS idx_aportes_miembro ON "Financiamientos"."Aportes_Grupo"(miembro_id);

-- 5. Habilitar RLS (Row Level Security)
ALTER TABLE "Financiamientos"."Grupos_Ahorro" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Financiamientos"."Miembros_Grupo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Financiamientos"."Aportes_Grupo" ENABLE ROW LEVEL SECURITY;

-- Política permisiva para desarrollo
CREATE POLICY "Allow all for Grupos_Ahorro" ON "Financiamientos"."Grupos_Ahorro" FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for Miembros_Grupo" ON "Financiamientos"."Miembros_Grupo" FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for Aportes_Grupo" ON "Financiamientos"."Aportes_Grupo" FOR ALL USING (true) WITH CHECK (true);
