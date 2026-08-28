-- =========================================================
-- PASO 10
-- CONSULTAS DEL SISTEMA
-- BAZAR CARMELITO
-- =========================================================

PRAGMA foreign_keys = ON;


-- =========================================================
-- 1. MOSTRAR TODOS LOS PRODUCTOS
-- =========================================================

SELECT
    p.id_producto,
    p.codigo,
    p.nombre,
    c.nombre AS categoria,
    m.nombre AS marca,
    pr.nombre AS presentacion
FROM producto p
JOIN categoria c
    ON p.id_categoria = c.id_categoria
LEFT JOIN marca m
    ON p.id_marca = m.id_marca
JOIN presentacion pr
    ON p.id_presentacion = pr.id_presentacion
ORDER BY p.id_producto;


-- =========================================================
-- 2. MOSTRAR INVENTARIO ACTUAL
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo,
    i.ultima_actualizacion
FROM inventario i
JOIN producto p
    ON i.id_producto = p.id_producto
ORDER BY p.nombre;


-- =========================================================
-- 3. MOSTRAR TODAS LAS VENTAS
-- =========================================================

SELECT
    v.id_venta,
    v.numero_venta,
    v.fecha_venta,
    v.hora_venta,
    v.subtotal,
    v.descuento_total,
    v.total,
    v.estado
FROM venta v
ORDER BY v.fecha_venta, v.hora_venta;


-- =========================================================
-- 4. MOSTRAR EL DETALLE DE TODAS LAS VENTAS
-- =========================================================

SELECT
    v.numero_venta,
    v.fecha_venta,
    p.nombre AS producto,
    dv.cantidad,
    dv.precio_unitario,
    dv.descuento,
    dv.subtotal
FROM venta v
JOIN detalle_venta dv
    ON v.id_venta = dv.id_venta
JOIN producto p
    ON dv.id_producto = p.id_producto
ORDER BY v.fecha_venta, v.numero_venta;


-- =========================================================
-- 5. PRODUCTOS MAS VENDIDOS EN AGOSTO
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    SUM(dv.cantidad) AS unidades_vendidas
FROM producto p
JOIN detalle_venta dv
    ON p.id_producto = dv.id_producto
JOIN venta v
    ON dv.id_venta = v.id_venta
WHERE v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
  AND v.estado = 'Completada'
GROUP BY
    p.id_producto,
    p.nombre
ORDER BY unidades_vendidas DESC;


-- =========================================================
-- 6. PRODUCTOS MENOS VENDIDOS EN AGOSTO
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas
FROM producto p
LEFT JOIN detalle_venta dv
    ON p.id_producto = dv.id_producto
LEFT JOIN venta v
    ON dv.id_venta = v.id_venta
    AND v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
    AND v.estado = 'Completada'
GROUP BY
    p.id_producto,
    p.nombre
ORDER BY unidades_vendidas ASC;


-- =========================================================
-- 7. STOCK ACTUAL VS STOCK MINIMO
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo
FROM inventario i
JOIN producto p
    ON i.id_producto = p.id_producto
ORDER BY i.stock_actual ASC;


-- =========================================================
-- 8. PRODUCTOS QUE YA NECESITAN REPOSICION
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo
FROM inventario i
JOIN producto p
    ON i.id_producto = p.id_producto
WHERE i.stock_actual <= i.stock_minimo
ORDER BY i.stock_actual ASC;


-- =========================================================
-- 9. PRODUCTOS PROXIMOS A NECESITAR REPOSICION
-- Consideramos próximos si están hasta un 50 % por encima
-- del stock mínimo
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    i.stock_actual,
    i.stock_minimo,
    ROUND(i.stock_minimo * 1.5, 2) AS limite_alerta
FROM inventario i
JOIN producto p
    ON i.id_producto = p.id_producto
WHERE i.stock_actual > i.stock_minimo
  AND i.stock_actual <= (i.stock_minimo * 1.5)
ORDER BY i.stock_actual ASC;


-- =========================================================
-- 10. ROTACION SIMPLE DE PRODUCTOS
-- Porcentaje vendido respecto al stock inicial aproximado
-- stock inicial = stock actual + unidades vendidas
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,
    COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas,
    i.stock_actual,
    i.stock_actual + COALESCE(SUM(dv.cantidad), 0) AS stock_inicial_estimado,

    ROUND(
        (
            COALESCE(SUM(dv.cantidad), 0) * 100.0
        )
        /
        NULLIF(
            i.stock_actual + COALESCE(SUM(dv.cantidad), 0),
            0
        ),
        2
    ) AS porcentaje_rotacion

FROM producto p

JOIN inventario i
    ON p.id_producto = i.id_producto

LEFT JOIN detalle_venta dv
    ON p.id_producto = dv.id_producto

LEFT JOIN venta v
    ON dv.id_venta = v.id_venta
    AND v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
    AND v.estado = 'Completada'

GROUP BY
    p.id_producto,
    p.nombre,
    i.stock_actual

ORDER BY porcentaje_rotacion DESC;


-- =========================================================
-- 11. CLASIFICACION DE ROTACION
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,

    COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas,

    i.stock_actual,

    ROUND(
        (
            COALESCE(SUM(dv.cantidad), 0) * 100.0
        )
        /
        NULLIF(
            i.stock_actual + COALESCE(SUM(dv.cantidad), 0),
            0
        ),
        2
    ) AS porcentaje_rotacion,

    CASE

        WHEN
            (
                COALESCE(SUM(dv.cantidad), 0) * 100.0
            )
            /
            NULLIF(
                i.stock_actual + COALESCE(SUM(dv.cantidad), 0),
                0
            ) >= 50
        THEN 'ALTA'

        WHEN
            (
                COALESCE(SUM(dv.cantidad), 0) * 100.0
            )
            /
            NULLIF(
                i.stock_actual + COALESCE(SUM(dv.cantidad), 0),
                0
            ) >= 25
        THEN 'MEDIA'

        ELSE 'BAJA'

    END AS nivel_rotacion

FROM producto p

JOIN inventario i
    ON p.id_producto = i.id_producto

LEFT JOIN detalle_venta dv
    ON p.id_producto = dv.id_producto

LEFT JOIN venta v
    ON dv.id_venta = v.id_venta
    AND v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
    AND v.estado = 'Completada'

GROUP BY
    p.id_producto,
    p.nombre,
    i.stock_actual

ORDER BY porcentaje_rotacion DESC;


-- =========================================================
-- 12. RECOMENDACION DE REPOSICION
-- =========================================================

SELECT
    p.id_producto,
    p.nombre,

    COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas,

    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo,

    CASE

        WHEN i.stock_actual <= i.stock_minimo
        THEN 'REPOSICION URGENTE'

        WHEN i.stock_actual <= (i.stock_minimo * 1.5)
        THEN 'REPOSICION PROXIMA'

        ELSE 'STOCK SUFICIENTE'

    END AS recomendacion

FROM producto p

JOIN inventario i
    ON p.id_producto = i.id_producto

LEFT JOIN detalle_venta dv
    ON p.id_producto = dv.id_producto

LEFT JOIN venta v
    ON dv.id_venta = v.id_venta
    AND v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
    AND v.estado = 'Completada'

GROUP BY
    p.id_producto,
    p.nombre,
    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo

ORDER BY i.stock_actual ASC;


-- =========================================================
-- 13. TOTAL DE VENTAS REALIZADAS EN AGOSTO
-- =========================================================

SELECT
    COUNT(*) AS cantidad_ventas,
    SUM(total) AS total_recaudado
FROM venta
WHERE fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
  AND estado = 'Completada';


-- =========================================================
-- 14. CANTIDAD TOTAL DE UNIDADES VENDIDAS
-- =========================================================

SELECT
    SUM(dv.cantidad) AS total_unidades_vendidas
FROM detalle_venta dv
JOIN venta v
    ON dv.id_venta = v.id_venta
WHERE v.fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
  AND v.estado = 'Completada';


-- =========================================================
-- 15. RESUMEN GENERAL DEL SISTEMA
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM producto) AS total_productos,
    (
        SELECT COUNT(*)
        FROM venta
        WHERE fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
    ) AS total_ventas_agosto,
    (
        SELECT COALESCE(SUM(total), 0)
        FROM venta
        WHERE fecha_venta BETWEEN '2026-08-01' AND '2026-08-31'
          AND estado = 'Completada'
    ) AS ingresos_agosto;