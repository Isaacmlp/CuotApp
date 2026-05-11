-- ============================================================
-- MIGRACIÓN: Módulo de Administración y Roles
-- Ejecutar en Supabase SQL Editor (schema: Usuarios)
-- ============================================================

-- 1. Modificar tabla Usuarios: agregar campos de rol y estado
ALTER TABLE "Usuarios"."Usuarios"
  ADD COLUMN IF NOT EXISTS rol TEXT DEFAULT 'cliente'
    CHECK (rol IN ('admin', 'supervisor', 'empleado', 'cliente')),
  ADD COLUMN IF NOT EXISTS creado_por TEXT,
  ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS fecha_creacion TIMESTAMPTZ DEFAULT NOW();

-- 2. Asignar rol admin a los correos especificados
UPDATE "Usuarios"."Usuarios" SET rol = 'admin'
  WHERE "Correo_Electronico" IN ('Isaacmlp714@gmail.com', 'enrriquestovar@gmail.com');

-- 3. Tabla de Bitácora de Actividad
CREATE TABLE IF NOT EXISTS "Usuarios"."Bitacora_Actividad" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_nombre TEXT NOT NULL,
    accion TEXT NOT NULL,
    descripcion TEXT,
    entidad_tipo TEXT,
    entidad_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabla de Créditos Compartidos
CREATE TABLE IF NOT EXISTS "Usuarios"."Creditos_Compartidos" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credito_id UUID NOT NULL,
    tipo_entidad TEXT DEFAULT 'credito'
      CHECK (tipo_entidad IN ('credito', 'grupo_ahorro')),
    propietario_nombre TEXT NOT NULL,
    trabajador_nombre TEXT NOT NULL,
    permisos TEXT DEFAULT 'lectura'
      CHECK (permisos IN ('lectura', 'cobro', 'total')),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_bitacora_usuario
    ON "Usuarios"."Bitacora_Actividad"(usuario_nombre);
CREATE INDEX IF NOT EXISTS idx_bitacora_fecha
    ON "Usuarios"."Bitacora_Actividad"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_creditos_compartidos_trabajador
    ON "Usuarios"."Creditos_Compartidos"(trabajador_nombre);
CREATE INDEX IF NOT EXISTS idx_creditos_compartidos_propietario
    ON "Usuarios"."Creditos_Compartidos"(propietario_nombre);
CREATE INDEX IF NOT EXISTS idx_creditos_compartidos_credito
    ON "Usuarios"."Creditos_Compartidos"(credito_id);

-- 6. Habilitar RLS
ALTER TABLE "Usuarios"."Bitacora_Actividad" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Usuarios"."Creditos_Compartidos" ENABLE ROW LEVEL SECURITY;

-- 7. Políticas permisivas para desarrollo
CREATE POLICY "Allow all for Bitacora_Actividad"
    ON "Usuarios"."Bitacora_Actividad"
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for Creditos_Compartidos"
    ON "Usuarios"."Creditos_Compartidos"
    FOR ALL USING (true) WITH CHECK (true);
