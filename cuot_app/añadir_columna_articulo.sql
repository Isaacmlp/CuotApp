-- Ejecuta este comando en el editor SQL de Supabase (SQL Editor)
-- para añadir los campos necesarios para la configuración de turnos y cuotas.

ALTER TABLE "Financiamientos"."Grupos_Ahorro" ADD COLUMN IF NOT EXISTS cantidad_participantes INT DEFAULT 0;
ALTER TABLE "Financiamientos"."Miembros_Grupo" ADD COLUMN IF NOT EXISTS notas_compra TEXT;
ALTER TABLE "Financiamientos"."Miembros_Grupo" ADD COLUMN IF NOT EXISTS numero_turno INT;
ALTER TABLE "Financiamientos"."Miembros_Grupo" ADD COLUMN IF NOT EXISTS monto_cuota NUMERIC(12,2) DEFAULT 0;
