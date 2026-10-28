-- 15 perritos de prueba. Claves UUID fijas + INSERT OR IGNORE => no se duplican.
INSERT OR IGNORE INTO perritos
  (id_raza, nombre, descripcion, color_principal, latitud, longitud, foto, clave_idempotencia)
VALUES
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Max', 'Perrito amigable de tamaño mediano',
 (SELECT id_color FROM colores WHERE nombre='Dorado'),
 25.438, -100.973, 'pruebas/max.png', '10000000-0000-4000-8000-000000000001'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Luna', 'Perrita pequeña de color claro',
 (SELECT id_color FROM colores WHERE nombre='Crema'),
 25.44, -100.975, 'pruebas/luna.png', '10000000-0000-4000-8000-000000000002'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Rocky', 'Perrito de tamaño grande',
 (SELECT id_color FROM colores WHERE nombre='Negro'),
 25.442, -100.977, 'pruebas/rocky.png', '10000000-0000-4000-8000-000000000003'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Milo', 'Perrito criollo de color café',
 (SELECT id_color FROM colores WHERE nombre='Café'),
 25.444, -100.979, 'pruebas/milo.png', '10000000-0000-4000-8000-000000000004'),
((SELECT id_raza FROM razas WHERE nombre='Beagle'), 'Toby', 'Perrito de color blanco y café',
 (SELECT id_color FROM colores WHERE nombre='Blanco'),
 25.446, -100.981, 'pruebas/toby.png', '10000000-0000-4000-8000-000000000005'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Nala', 'Perrita de pelaje gris',
 (SELECT id_color FROM colores WHERE nombre='Gris'),
 25.448, -100.983, 'pruebas/nala.png', '10000000-0000-4000-8000-000000000006'),
((SELECT id_raza FROM razas WHERE nombre='Golden Retriever'), 'Bobby', 'Perrito de pelaje dorado',
 (SELECT id_color FROM colores WHERE nombre='Dorado'),
 25.45, -100.985, 'pruebas/bobby.png', '10000000-0000-4000-8000-000000000007'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Coco', 'Perrito de color blanco',
 (SELECT id_color FROM colores WHERE nombre='Blanco'),
 25.452, -100.987, 'pruebas/coco.png', '10000000-0000-4000-8000-000000000008'),
((SELECT id_raza FROM razas WHERE nombre='Boxer'), 'Bruno', 'Perrito de color atigrado',
 (SELECT id_color FROM colores WHERE nombre='Atigrado'),
 25.454, -100.989, 'pruebas/bruno.png', '10000000-0000-4000-8000-000000000009'),
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Pecas', 'Perrito blanco con manchas',
 (SELECT id_color FROM colores WHERE nombre='Manchado'),
 25.456, -100.991, 'pruebas/pecas.png', '10000000-0000-4000-8000-000000000010'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Thor', 'Perrito de pelaje oscuro',
 (SELECT id_color FROM colores WHERE nombre='Negro'),
 25.458, -100.993, 'pruebas/thor.png', '10000000-0000-4000-8000-000000000011'),
((SELECT id_raza FROM razas WHERE nombre='Schnauzer'), 'Lola', 'Perrita de color gris',
 (SELECT id_color FROM colores WHERE nombre='Gris'),
 25.46, -100.995, 'pruebas/lola.png', '10000000-0000-4000-8000-000000000012'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Simba', 'Perrito de color canela',
 (SELECT id_color FROM colores WHERE nombre='Canela'),
 25.462, -100.997, 'pruebas/simba.png', '10000000-0000-4000-8000-000000000013'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Chispa', 'Perrita de color rojizo',
 (SELECT id_color FROM colores WHERE nombre='Rojizo'),
 25.464, -100.999, 'pruebas/chispa.png', '10000000-0000-4000-8000-000000000014'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Oso', 'Perrito de color marrón',
 (SELECT id_color FROM colores WHERE nombre='Marrón'),
 25.466, -101.001, 'pruebas/oso.png', '10000000-0000-4000-8000-000000000015');

-- Colores adicionales de prueba
INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Blanco'
WHERE p.clave_idempotencia IN ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000004');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Café'
WHERE p.clave_idempotencia IN ('10000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000010');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Negro'
WHERE p.clave_idempotencia IN ('10000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000015');
