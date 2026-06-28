-- =========================
-- EXTENSIONES
-- =========================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- =========================
-- ENUMS
-- =========================

CREATE TYPE estado_cita AS ENUM (
  'pendiente',
  'confirmada',
  'cancelada',
  'realizada',
  'no_asistio'
);

CREATE TYPE estado_tatuaje AS ENUM (
  'cotizado',
  'en_proceso',
  'terminado',
  'cancelado'
);

CREATE TYPE metodo_pago AS ENUM (
  'efectivo',
  'transferencia',
  'tarjeta',
  'otro'
);

CREATE TYPE estado_pago AS ENUM (
  'pendiente',
  'pagado',
  'cancelado',
  'reembolsado'
);

CREATE TYPE categoria_gasto AS ENUM (
  'renta',
  'material',
  'publicidad',
  'transporte',
  'equipo',
  'otro'
);

CREATE TYPE unidad_material AS ENUM (
  'pieza',
  'ml',
  'gramos',
  'caja'
);

CREATE TYPE tipo_movimiento_inventario AS ENUM (
  'entrada',
  'uso',
  'ajuste',
  'merma'
);

CREATE TYPE severidad_alergia AS ENUM (
  'leve',
  'moderada',
  'severa'
);


-- =========================
-- TRIGGER UPDATED_AT
-- =========================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =========================
-- TATUADORES
-- =========================

CREATE TABLE tatuadores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(150) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  foto_perfil_url TEXT,
  telefono VARCHAR(30),
  descripcion TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_tatuadores_updated_at
BEFORE UPDATE ON tatuadores
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- =========================
-- ESTILOS
-- =========================

CREATE TABLE estilos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE tatuador_estilos (
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,
  estilo_id UUID NOT NULL REFERENCES estilos(id) ON DELETE CASCADE,
  PRIMARY KEY (tatuador_id, estilo_id)
);


-- =========================
-- CLIENTES
-- =========================

CREATE TABLE clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,
  nombre VARCHAR(150) NOT NULL,
  telefono VARCHAR(30),
  correo VARCHAR(255),
  fecha_nacimiento DATE,
  notas TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_clientes_updated_at
BEFORE UPDATE ON clientes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- =========================
-- CITAS
-- =========================

CREATE TABLE citas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,

  fecha_inicio TIMESTAMP NOT NULL,
  fecha_fin TIMESTAMP NOT NULL,

  zona_cuerpo VARCHAR(150),
  descripcion TEXT,
  estado estado_cita NOT NULL DEFAULT 'pendiente',

  precio_estimado NUMERIC(10,2) CHECK (precio_estimado >= 0),
  precio_final NUMERIC(10,2) CHECK (precio_final >= 0),
  anticipo NUMERIC(10,2) DEFAULT 0 CHECK (anticipo >= 0),

  ubicacion TEXT,
  consentimiento_firmado BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),

  CHECK (fecha_fin > fecha_inicio)
);

CREATE TRIGGER trg_citas_updated_at
BEFORE UPDATE ON citas
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- =========================
-- TATUAJES / PROYECTOS
-- =========================

CREATE TABLE tatuajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,

  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  zona_cuerpo VARCHAR(150),
  estilo VARCHAR(100),

  precio_total_estimado NUMERIC(10,2) CHECK (precio_total_estimado >= 0),
  precio_total_final NUMERIC(10,2) CHECK (precio_total_final >= 0),

  estado estado_tatuaje NOT NULL DEFAULT 'cotizado',

  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_tatuajes_updated_at
BEFORE UPDATE ON tatuajes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- =========================
-- SESIONES
-- =========================

CREATE TABLE sesiones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuaje_id UUID NOT NULL REFERENCES tatuajes(id) ON DELETE CASCADE,
  cita_id UUID REFERENCES citas(id) ON DELETE SET NULL,

  duracion_minutos INT CHECK (duracion_minutos > 0),
  notas TEXT,
  dolor_cliente INT CHECK (dolor_cliente BETWEEN 1 AND 10),
  avances TEXT,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- =========================
-- PAGOS
-- =========================

CREATE TABLE pagos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  cita_id UUID REFERENCES citas(id) ON DELETE SET NULL,
  tatuaje_id UUID REFERENCES tatuajes(id) ON DELETE SET NULL,

  monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
  metodo_pago metodo_pago NOT NULL,
  concepto VARCHAR(150),
  fecha_pago TIMESTAMP NOT NULL DEFAULT now(),
  estado estado_pago NOT NULL DEFAULT 'pagado',

  created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- =========================
-- GASTOS
-- =========================

CREATE TABLE gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,

  categoria categoria_gasto NOT NULL,
  descripcion TEXT,
  monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  recurrente BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- =========================
-- MATERIALES
-- =========================

CREATE TABLE materiales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tatuador_id UUID NOT NULL REFERENCES tatuadores(id) ON DELETE CASCADE,

  nombre VARCHAR(150) NOT NULL,
  categoria VARCHAR(100),
  marca VARCHAR(100),
  unidad unidad_material NOT NULL,

  costo_unitario NUMERIC(10,2) CHECK (costo_unitario >= 0),
  cantidad_actual NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (cantidad_actual >= 0),

  caducidad DATE,
  imagen_url TEXT,

  created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- =========================
-- MOVIMIENTOS DE INVENTARIO
-- =========================

CREATE TABLE movimientos_inventario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID NOT NULL REFERENCES materiales(id) ON DELETE CASCADE,

  tipo tipo_movimiento_inventario NOT NULL,
  cantidad NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
  costo_total NUMERIC(10,2) CHECK (costo_total >= 0),

  cita_id UUID REFERENCES citas(id) ON DELETE SET NULL,
  sesion_id UUID REFERENCES sesiones(id) ON DELETE SET NULL,

  notas TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- =========================
-- MATERIALES USADOS POR SESIÓN
-- =========================

CREATE TABLE sesion_materiales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sesion_id UUID NOT NULL REFERENCES sesiones(id) ON DELETE CASCADE,
  material_id UUID NOT NULL REFERENCES materiales(id) ON DELETE RESTRICT,

  cantidad_usada NUMERIC(10,2) NOT NULL CHECK (cantidad_usada > 0),
  costo_calculado NUMERIC(10,2) CHECK (costo_calculado >= 0),

  UNIQUE (sesion_id, material_id)
);


-- =========================
-- CONSENTIMIENTOS
-- =========================

CREATE TABLE consentimientos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  cita_id UUID REFERENCES citas(id) ON DELETE SET NULL,

  firmado BOOLEAN NOT NULL DEFAULT false,
  archivo_url TEXT,
  fecha_firma TIMESTAMP
);


-- =========================
-- ALERGIAS
-- =========================

CREATE TABLE alergias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,

  descripcion TEXT NOT NULL,
  severidad severidad_alergia
);


-- =========================
-- INSERTS INICIALES
-- =========================

INSERT INTO estilos (nombre) VALUES
  ('Blackwork'),
  ('Realismo'),
  ('Tradicional'),
  ('Fine line'),
  ('Anime')
ON CONFLICT (nombre) DO NOTHING;


-- =========================
-- ÍNDICES RECOMENDADOS
-- =========================

CREATE INDEX idx_clientes_tatuador_id ON clientes(tatuador_id);
CREATE INDEX idx_citas_tatuador_id ON citas(tatuador_id);
CREATE INDEX idx_citas_cliente_id ON citas(cliente_id);
CREATE INDEX idx_citas_fecha_inicio ON citas(fecha_inicio);
CREATE INDEX idx_tatuajes_cliente_id ON tatuajes(cliente_id);
CREATE INDEX idx_sesiones_tatuaje_id ON sesiones(tatuaje_id);
CREATE INDEX idx_pagos_tatuador_id ON pagos(tatuador_id);
CREATE INDEX idx_pagos_cliente_id ON pagos(cliente_id);
CREATE INDEX idx_gastos_tatuador_id ON gastos(tatuador_id);
CREATE INDEX idx_materiales_tatuador_id ON materiales(tatuador_id);
CREATE INDEX idx_movimientos_material_id ON movimientos_inventario(material_id);