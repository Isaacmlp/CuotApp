-- Ejecuta este comando en el editor SQL de Supabase (SQL Editor)
-- para añadir el campo de artículo deseado al módulo de grupos de ahorro.

ALTER TABLE "Financiamientos"."Miembros_Grupo" 
ADD COLUMN IF NOT EXISTS notas_compra TEXT;
