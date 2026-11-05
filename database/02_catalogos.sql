-- Catálogos base (14 razas y 13 colores). INSERT OR IGNORE => se puede repetir sin duplicar.
INSERT OR IGNORE INTO razas (nombre) VALUES
('Sin raza definida / criollo'),('Labrador Retriever'),('Pastor Alemán'),('Golden Retriever'),
('Chihuahua'),('Poodle'),('Beagle'),('Husky Siberiano'),('Rottweiler'),('Pug'),
('Bulldog'),('Boxer'),('Schnauzer'),('Dálmata');

INSERT OR IGNORE INTO colores (nombre) VALUES
('Negro'),('Blanco'),('Café'),('Marrón'),('Gris'),('Dorado'),('Crema'),
('Beige'),('Canela'),('Atigrado'),('Manchado'),('Rojizo');

-- P2: "Negro y blanco" son DOS colores (principal + adicional). Se desactiva para que
-- no rompa la similitud de colores (Jaccard). activo=0 conserva los registros viejos.
UPDATE colores SET activo = 0 WHERE nombre = 'Negro y blanco';
