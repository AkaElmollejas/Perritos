-- P2: 90 avistamientos de muestra (con los 15 del P1 suman 105).
-- 70 perros en 5 zonas, 20 de ellos sin verse desde septiembre y 20 reportes
-- repetidos (otro nombre, a menos de 100 m) para lucir duplicados y línea de tiempo.
-- Claves UUID fijas + INSERT OR IGNORE => se puede repetir sin duplicar.
INSERT OR IGNORE INTO perritos
  (id_raza, nombre, color_principal, latitud, longitud, foto, fecha_registro, clave_idempotencia)
VALUES
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Rufo', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.419429, -100.99297, 'pruebas/simba.png', '2026-10-19 16:26:00', '20000000-0000-4000-8000-000000000001'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Canela', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.445871, -100.975891, 'pruebas/toby.png', '2026-10-18 09:07:00', '20000000-0000-4000-8000-000000000002'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Pelusa', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.459801, -100.990604, 'pruebas/oso.png', '2026-09-20 12:22:00', '20000000-0000-4000-8000-000000000003'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Bola', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.43628, -101.011484, 'pruebas/toby.png', '2026-10-11 16:18:00', '20000000-0000-4000-8000-000000000004'),
((SELECT id_raza FROM razas WHERE nombre='Pug'), 'Nube', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.469489, -100.955482, 'pruebas/bobby.png', '2026-09-17 13:29:00', '20000000-0000-4000-8000-000000000005'),
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Sol', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.419088, -100.988308, 'pruebas/bruno.png', '2026-10-02 14:58:00', '20000000-0000-4000-8000-000000000006'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Tigre', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.442104, -100.98096, 'pruebas/rocky.png', '2026-10-13 11:49:00', '20000000-0000-4000-8000-000000000007'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Chiquis', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.459818, -100.984447, 'pruebas/oso.png', '2026-10-01 11:54:00', '20000000-0000-4000-8000-000000000008'),
((SELECT id_raza FROM razas WHERE nombre='Boxer'), 'Manchas', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.433464, -101.007592, 'pruebas/bruno.png', '2026-09-21 18:19:00', '20000000-0000-4000-8000-000000000009'),
((SELECT id_raza FROM razas WHERE nombre='Beagle'), 'Paco', (SELECT id_color FROM colores WHERE nombre='Crema'), 25.473598, -100.959977, 'pruebas/rocky.png', '2026-09-04 08:02:00', '20000000-0000-4000-8000-000000000010'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Kiko', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.425868, -100.991833, 'pruebas/coco.png', '2026-09-03 19:31:00', '20000000-0000-4000-8000-000000000011'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Dulce', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.445135, -100.976086, 'pruebas/oso.png', '2026-09-07 13:29:00', '20000000-0000-4000-8000-000000000012'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Lobo', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.459743, -100.990739, 'pruebas/toby.png', '2026-10-01 09:41:00', '20000000-0000-4000-8000-000000000013'),
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Mara', (SELECT id_color FROM colores WHERE nombre='Crema'), 25.442839, -101.011558, 'pruebas/coco.png', '2026-08-02 09:00:00', '20000000-0000-4000-8000-000000000014'),
(NULL, 'Zeus', (SELECT id_color FROM colores WHERE nombre='Marrón'), 25.470968, -100.954814, 'pruebas/bruno.png', '2026-10-19 08:48:00', '20000000-0000-4000-8000-000000000015'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Pinto', (SELECT id_color FROM colores WHERE nombre='Negro'), 25.429476, -100.990978, 'pruebas/oso.png', '2026-10-14 17:49:00', '20000000-0000-4000-8000-000000000016'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Fiona', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.450399, -100.980096, 'pruebas/oso.png', '2026-10-15 10:38:00', '20000000-0000-4000-8000-000000000017'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Duque', (SELECT id_color FROM colores WHERE nombre='Café'), 25.458311, -100.992512, 'pruebas/rocky.png', '2026-09-22 14:51:00', '20000000-0000-4000-8000-000000000018'),
(NULL, 'Tornado', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.43824, -101.01364, 'pruebas/oso.png', '2026-09-14 18:22:00', '20000000-0000-4000-8000-000000000019'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Galleta', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.473234, -100.965691, 'pruebas/coco.png', '2026-09-11 09:31:00', '20000000-0000-4000-8000-000000000020'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Panda', (SELECT id_color FROM colores WHERE nombre='Marrón'), 25.424859, -100.989341, 'pruebas/thor.png', '2026-09-28 17:14:00', '20000000-0000-4000-8000-000000000021'),
(NULL, 'Ñoño', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.447531, -100.979432, 'pruebas/chispa.png', '2026-10-22 16:59:00', '20000000-0000-4000-8000-000000000022'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Estrella', (SELECT id_color FROM colores WHERE nombre='Rojizo'), 25.450578, -100.985583, 'pruebas/milo.png', '2026-08-17 18:33:00', '20000000-0000-4000-8000-000000000023'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Bandido', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.441425, -101.009798, 'pruebas/bobby.png', '2026-09-04 14:34:00', '20000000-0000-4000-8000-000000000024'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Mora', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.474417, -100.961402, 'pruebas/nala.png', '2026-09-06 15:11:00', '20000000-0000-4000-8000-000000000025'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Trueno', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.424232, -100.993665, 'pruebas/luna.png', '2026-08-28 11:00:00', '20000000-0000-4000-8000-000000000026'),
((SELECT id_raza FROM razas WHERE nombre='Schnauzer'), 'Pepe', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.449543, -100.978252, 'pruebas/nala.png', '2026-09-15 21:10:00', '20000000-0000-4000-8000-000000000027'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Gordo', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.456744, -100.989132, 'pruebas/pecas.png', '2026-10-12 19:13:00', '20000000-0000-4000-8000-000000000028'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Flaca', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.435536, -101.012783, 'pruebas/thor.png', '2026-09-25 10:06:00', '20000000-0000-4000-8000-000000000029'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Rayo', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.464725, -100.961725, 'pruebas/pecas.png', '2026-10-04 13:17:00', '20000000-0000-4000-8000-000000000030'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Rufo 2', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.428049, -100.995508, 'pruebas/oso.png', '2026-08-02 14:55:00', '20000000-0000-4000-8000-000000000031'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Canela 2', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.449859, -100.982915, 'pruebas/thor.png', '2026-09-09 09:06:00', '20000000-0000-4000-8000-000000000032'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Pelusa 2', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.456734, -100.984143, 'pruebas/milo.png', '2026-09-21 13:38:00', '20000000-0000-4000-8000-000000000033'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Bola 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.439129, -101.010887, 'pruebas/chispa.png', '2026-09-02 14:18:00', '20000000-0000-4000-8000-000000000034'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Nube 2', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.468276, -100.957175, 'pruebas/bobby.png', '2026-08-16 12:49:00', '20000000-0000-4000-8000-000000000035'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Sol 2', (SELECT id_color FROM colores WHERE nombre='Marrón'), 25.421827, -100.988164, 'pruebas/luna.png', '2026-08-15 10:39:00', '20000000-0000-4000-8000-000000000036'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Tigre 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.440419, -100.984492, 'pruebas/nala.png', '2026-09-24 17:08:00', '20000000-0000-4000-8000-000000000037'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Chiquis 2', (SELECT id_color FROM colores WHERE nombre='Marrón'), 25.454984, -100.991474, 'pruebas/lola.png', '2026-10-09 08:42:00', '20000000-0000-4000-8000-000000000038'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Manchas 2', (SELECT id_color FROM colores WHERE nombre='Café'), 25.443216, -101.007795, 'pruebas/coco.png', '2026-08-03 12:34:00', '20000000-0000-4000-8000-000000000039'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Paco 2', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.469015, -100.954498, 'pruebas/thor.png', '2026-08-23 16:02:00', '20000000-0000-4000-8000-000000000040'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Kiko 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.428394, -100.989115, 'pruebas/thor.png', '2026-10-24 21:00:00', '20000000-0000-4000-8000-000000000041'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Dulce 2', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.450738, -100.980353, 'pruebas/bruno.png', '2026-09-16 20:14:00', '20000000-0000-4000-8000-000000000042'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Lobo 2', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.459949, -100.991876, 'pruebas/rocky.png', '2026-10-14 12:12:00', '20000000-0000-4000-8000-000000000043'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Mara 2', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.439536, -101.014155, 'pruebas/bruno.png', '2026-08-11 12:23:00', '20000000-0000-4000-8000-000000000044'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Zeus 2', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.472772, -100.964344, 'pruebas/bobby.png', '2026-09-09 17:02:00', '20000000-0000-4000-8000-000000000045'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Pinto 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.422567, -100.987442, 'pruebas/lola.png', '2026-08-14 09:09:00', '20000000-0000-4000-8000-000000000046'),
((SELECT id_raza FROM razas WHERE nombre='Boxer'), 'Fiona 2', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.443671, -100.97943, 'pruebas/toby.png', '2026-09-07 12:34:00', '20000000-0000-4000-8000-000000000047'),
((SELECT id_raza FROM razas WHERE nombre='Boxer'), 'Duque 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.454287, -100.984327, 'pruebas/bobby.png', '2026-10-17 18:30:00', '20000000-0000-4000-8000-000000000048'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Tornado 2', (SELECT id_color FROM colores WHERE nombre='Café'), 25.436268, -101.006732, 'pruebas/rocky.png', '2026-08-23 13:34:00', '20000000-0000-4000-8000-000000000049'),
((SELECT id_raza FROM razas WHERE nombre='Boxer'), 'Galleta 2', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.465967, -100.955354, 'pruebas/toby.png', '2026-09-17 09:23:00', '20000000-0000-4000-8000-000000000050'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Panda 2', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.420594, -100.997149, 'pruebas/lola.png', '2026-08-07 21:53:00', '20000000-0000-4000-8000-000000000051'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Ñoño 2', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.439878, -100.982849, 'pruebas/chispa.png', '2026-09-05 16:15:00', '20000000-0000-4000-8000-000000000052'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Estrella 2', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.454304, -100.986217, 'pruebas/simba.png', '2026-08-06 20:31:00', '20000000-0000-4000-8000-000000000053'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Bandido 2', (SELECT id_color FROM colores WHERE nombre='Crema'), 25.435744, -101.00696, 'pruebas/rocky.png', '2026-09-01 14:20:00', '20000000-0000-4000-8000-000000000054'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Mora 2', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.466358, -100.960444, 'pruebas/lola.png', '2026-08-14 10:28:00', '20000000-0000-4000-8000-000000000055'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Trueno 2', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.424799, -100.990167, 'pruebas/bruno.png', '2026-08-29 12:09:00', '20000000-0000-4000-8000-000000000056'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Pepe 2', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.446523, -100.983188, 'pruebas/bobby.png', '2026-09-06 15:40:00', '20000000-0000-4000-8000-000000000057'),
((SELECT id_raza FROM razas WHERE nombre='Beagle'), 'Gordo 2', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.454793, -100.989403, 'pruebas/thor.png', '2026-09-01 18:54:00', '20000000-0000-4000-8000-000000000058'),
((SELECT id_raza FROM razas WHERE nombre='Golden Retriever'), 'Flaca 2', (SELECT id_color FROM colores WHERE nombre='Crema'), 25.443433, -101.007988, 'pruebas/bobby.png', '2026-08-22 08:59:00', '20000000-0000-4000-8000-000000000059'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Rayo 2', (SELECT id_color FROM colores WHERE nombre='Café'), 25.472693, -100.965874, 'pruebas/simba.png', '2026-09-09 14:53:00', '20000000-0000-4000-8000-000000000060'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Rufo 3', (SELECT id_color FROM colores WHERE nombre='Negro'), 25.427625, -100.988784, 'pruebas/toby.png', '2026-08-08 18:54:00', '20000000-0000-4000-8000-000000000061'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Canela 3', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.442919, -100.976643, 'pruebas/bruno.png', '2026-09-05 19:12:00', '20000000-0000-4000-8000-000000000062'),
((SELECT id_raza FROM razas WHERE nombre='Golden Retriever'), 'Pelusa 3', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.459227, -100.984209, 'pruebas/luna.png', '2026-08-11 19:19:00', '20000000-0000-4000-8000-000000000063'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Bola 3', (SELECT id_color FROM colores WHERE nombre='Café'), 25.438812, -101.007458, 'pruebas/max.png', '2026-08-02 12:26:00', '20000000-0000-4000-8000-000000000064'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Nube 3', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.466223, -100.957189, 'pruebas/coco.png', '2026-08-23 13:38:00', '20000000-0000-4000-8000-000000000065'),
((SELECT id_raza FROM razas WHERE nombre='Sin raza definida / criollo'), 'Sol 3', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.421064, -100.988401, 'pruebas/toby.png', '2026-08-31 20:23:00', '20000000-0000-4000-8000-000000000066'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Tigre 3', (SELECT id_color FROM colores WHERE nombre='Rojizo'), 25.449038, -100.980407, 'pruebas/bobby.png', '2026-09-07 08:52:00', '20000000-0000-4000-8000-000000000067'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Chiquis 3', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.460355, -100.987289, 'pruebas/bruno.png', '2026-09-09 09:54:00', '20000000-0000-4000-8000-000000000068'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Manchas 3', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.443693, -101.00885, 'pruebas/simba.png', '2026-08-05 16:55:00', '20000000-0000-4000-8000-000000000069'),
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Paco 3', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.466092, -100.96291, 'pruebas/coco.png', '2026-09-08 11:01:00', '20000000-0000-4000-8000-000000000070'),
((SELECT id_raza FROM razas WHERE nombre='Dálmata'), 'Gordo (vecino)', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.419014, -100.993084, 'pruebas/bruno.png', '2026-10-22 16:26:00', '20000000-0000-4000-8000-000000000071'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Manchas (vecino)', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.436302, -101.011017, 'pruebas/simba.png', '2026-10-19 16:18:00', '20000000-0000-4000-8000-000000000072'),
((SELECT id_raza FROM razas WHERE nombre='Husky Siberiano'), 'Gordo (vecino)', (SELECT id_color FROM colores WHERE nombre='Canela'), 25.441523, -100.980674, 'pruebas/nala.png', '2026-10-19 11:49:00', '20000000-0000-4000-8000-000000000073'),
((SELECT id_raza FROM razas WHERE nombre='Beagle'), 'Galleta (vecino)', (SELECT id_color FROM colores WHERE nombre='Crema'), 25.474394, -100.96015, 'pruebas/lola.png', '2026-09-13 08:02:00', '20000000-0000-4000-8000-000000000074'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Estrella (vecino)', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.459245, -100.990568, 'pruebas/rocky.png', '2026-10-04 09:41:00', '20000000-0000-4000-8000-000000000075'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Ñoño (vecino)', (SELECT id_color FROM colores WHERE nombre='Negro'), 25.428886, -100.990473, 'pruebas/pecas.png', '2026-10-15 17:49:00', '20000000-0000-4000-8000-000000000076'),
(NULL, 'Manchas (vecino)', (SELECT id_color FROM colores WHERE nombre='Blanco'), 25.438723, -101.013055, 'pruebas/simba.png', '2026-09-19 18:22:00', '20000000-0000-4000-8000-000000000077'),
(NULL, 'Manchas (vecino)', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.448237, -100.979946, 'pruebas/bruno.png', '2026-10-28 16:59:00', '20000000-0000-4000-8000-000000000078'),
((SELECT id_raza FROM razas WHERE nombre='Pastor Alemán'), 'Estrella (vecino)', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.473822, -100.961933, 'pruebas/max.png', '2026-09-09 15:11:00', '20000000-0000-4000-8000-000000000079'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Galleta (vecino)', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.457032, -100.98927, 'pruebas/coco.png', '2026-10-21 19:13:00', '20000000-0000-4000-8000-000000000080'),
((SELECT id_raza FROM razas WHERE nombre='Chihuahua'), 'Fiona (vecino)', (SELECT id_color FROM colores WHERE nombre='Gris'), 25.428781, -100.995827, 'pruebas/nala.png', '2026-08-11 14:55:00', '20000000-0000-4000-8000-000000000081'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Mara (vecino)', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.438476, -101.010598, 'pruebas/rocky.png', '2026-09-08 14:18:00', '20000000-0000-4000-8000-000000000082'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Pinto (vecino)', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.439852, -100.984479, 'pruebas/max.png', '2026-09-25 17:08:00', '20000000-0000-4000-8000-000000000083'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Estrella (vecino)', (SELECT id_color FROM colores WHERE nombre='Atigrado'), 25.468366, -100.95436, 'pruebas/lola.png', '2026-08-28 16:02:00', '20000000-0000-4000-8000-000000000084'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Fiona (vecino)', (SELECT id_color FROM colores WHERE nombre='Beige'), 25.459675, -100.992631, 'pruebas/milo.png', '2026-10-16 12:12:00', '20000000-0000-4000-8000-000000000085'),
((SELECT id_raza FROM razas WHERE nombre='Bulldog'), 'Pepe (vecino)', (SELECT id_color FROM colores WHERE nombre='Manchado'), 25.422444, -100.987549, 'pruebas/chispa.png', '2026-08-17 09:09:00', '20000000-0000-4000-8000-000000000086'),
((SELECT id_raza FROM razas WHERE nombre='Rottweiler'), 'Pinto (vecino)', (SELECT id_color FROM colores WHERE nombre='Café'), 25.435854, -101.006473, 'pruebas/milo.png', '2026-08-29 13:34:00', '20000000-0000-4000-8000-000000000087'),
((SELECT id_raza FROM razas WHERE nombre='Labrador Retriever'), 'Mara (vecino)', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.439332, -100.982062, 'pruebas/lola.png', '2026-09-12 16:15:00', '20000000-0000-4000-8000-000000000088'),
((SELECT id_raza FROM razas WHERE nombre='Poodle'), 'Tigre (vecino)', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.466293, -100.960663, 'pruebas/toby.png', '2026-08-22 10:28:00', '20000000-0000-4000-8000-000000000089'),
((SELECT id_raza FROM razas WHERE nombre='Beagle'), 'Pinto (vecino)', (SELECT id_color FROM colores WHERE nombre='Dorado'), 25.455489, -100.989309, 'pruebas/luna.png', '2026-09-05 18:54:00', '20000000-0000-4000-8000-000000000090');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Manchado'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000021', '20000000-0000-4000-8000-000000000045', '20000000-0000-4000-8000-000000000055', '20000000-0000-4000-8000-000000000060', '20000000-0000-4000-8000-000000000063', '20000000-0000-4000-8000-000000000071', '20000000-0000-4000-8000-000000000089');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Marrón'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000011', '20000000-0000-4000-8000-000000000067');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Negro'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000019', '20000000-0000-4000-8000-000000000022', '20000000-0000-4000-8000-000000000027', '20000000-0000-4000-8000-000000000032', '20000000-0000-4000-8000-000000000037', '20000000-0000-4000-8000-000000000039', '20000000-0000-4000-8000-000000000041', '20000000-0000-4000-8000-000000000044', '20000000-0000-4000-8000-000000000066', '20000000-0000-4000-8000-000000000077', '20000000-0000-4000-8000-000000000078', '20000000-0000-4000-8000-000000000083');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Café'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000013', '20000000-0000-4000-8000-000000000019', '20000000-0000-4000-8000-000000000038', '20000000-0000-4000-8000-000000000044', '20000000-0000-4000-8000-000000000047', '20000000-0000-4000-8000-000000000066', '20000000-0000-4000-8000-000000000069', '20000000-0000-4000-8000-000000000072', '20000000-0000-4000-8000-000000000075', '20000000-0000-4000-8000-000000000077');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Atigrado'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000009', '20000000-0000-4000-8000-000000000018', '20000000-0000-4000-8000-000000000043', '20000000-0000-4000-8000-000000000085');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Canela'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000014', '20000000-0000-4000-8000-000000000025', '20000000-0000-4000-8000-000000000028', '20000000-0000-4000-8000-000000000034', '20000000-0000-4000-8000-000000000043', '20000000-0000-4000-8000-000000000046', '20000000-0000-4000-8000-000000000051', '20000000-0000-4000-8000-000000000052', '20000000-0000-4000-8000-000000000079', '20000000-0000-4000-8000-000000000080', '20000000-0000-4000-8000-000000000082', '20000000-0000-4000-8000-000000000085', '20000000-0000-4000-8000-000000000086', '20000000-0000-4000-8000-000000000088');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Gris'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000010', '20000000-0000-4000-8000-000000000067', '20000000-0000-4000-8000-000000000074');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Beige'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000013', '20000000-0000-4000-8000-000000000017', '20000000-0000-4000-8000-000000000020', '20000000-0000-4000-8000-000000000025', '20000000-0000-4000-8000-000000000055', '20000000-0000-4000-8000-000000000068', '20000000-0000-4000-8000-000000000075', '20000000-0000-4000-8000-000000000079', '20000000-0000-4000-8000-000000000089');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Blanco'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000015', '20000000-0000-4000-8000-000000000052', '20000000-0000-4000-8000-000000000062', '20000000-0000-4000-8000-000000000070', '20000000-0000-4000-8000-000000000088');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Rojizo'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000016', '20000000-0000-4000-8000-000000000059', '20000000-0000-4000-8000-000000000061', '20000000-0000-4000-8000-000000000070', '20000000-0000-4000-8000-000000000076');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Crema'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000021', '20000000-0000-4000-8000-000000000024', '20000000-0000-4000-8000-000000000042');

INSERT OR IGNORE INTO perrito_colores (id_perrito, id_color)
SELECT p.id_perrito, c.id_color FROM perritos p JOIN colores c ON c.nombre = 'Dorado'
WHERE p.clave_idempotencia IN ('20000000-0000-4000-8000-000000000035', '20000000-0000-4000-8000-000000000054', '20000000-0000-4000-8000-000000000056', '20000000-0000-4000-8000-000000000057', '20000000-0000-4000-8000-000000000065');
