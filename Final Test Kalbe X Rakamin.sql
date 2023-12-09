SELECT
  d.driver_id,
  d.driver_name,
  COUNT(sd.shipment_detail_id) AS total_pengiriman
FROM
  app.driver d
JOIN
  app."shipment detail" sd ON d.driver_id = sd.driver_id
JOIN
  app.shipment s ON sd.shipment_id = s.shipment_id
WHERE
  EXTRACT(MONTH FROM CAST(s.sending_time AS TIMESTAMP)) = 5
  AND EXTRACT(YEAR FROM CAST(s.sending_time AS TIMESTAMP)) = 2023
GROUP BY
  d.driver_id, d.driver_name
ORDER BY
  total_pengiriman DESC
LIMIT 2;


=======================================================================================================================================
-------------------------------------------------------------------------------------------------------------------------


UPDATE app.shipment
SET driver_id = 1
WHERE shipment_id IN (1, 2, 3);

UPDATE app.shipment
SET driver_id = 2
WHERE shipment_id IN (4, 5, 6);

UPDATE app.shipment
SET driver_id = 3
WHERE shipment_id IN (7, 8, 9, 10, 11, 12, 13);


=============================================================================================================================
--------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
  p.product_name,
  COUNT(sd.shipment_detail_id) AS total_pengiriman
FROM
  app.shipment s
JOIN
  app."shipment detail" sd ON s.shipment_id = sd.shipment_id
JOIN
  app.product p ON s.Product_id = p.id_product
WHERE
  EXTRACT(MONTH FROM CAST(s.sending_time AS TIMESTAMP)) = 5
  AND EXTRACT(YEAR FROM CAST(s.sending_time AS TIMESTAMP)) = 2023
GROUP BY
  p.id_product, p.product_name
ORDER BY
  p.id_product
LIMIT 10;


=================================================================================================================================
--------------------------------------------------------------------------------------------------------------------------------------


SELECT
  s.shipment_id,
  s.store_id,
  s.product_id,
  p.product_name,
  s.sending_time,
  s.delivered_time,
  s.receiver
FROM
  app.shipment s
JOIN
  app.product p ON s.product_id = p.id_product
LEFT JOIN
  app."shipment detail" sd ON s.shipment_id = sd.shipment_id
WHERE
  sd.shipment_detail_id IS NULL
  AND s.delivered_time IS NULL;
  
 
 SELECT
  p.id_product,
  p.product_name
FROM
  app.product p
WHERE
  p.id_product >= 14
  AND p.id_product NOT IN (
    SELECT DISTINCT s.product_id
    FROM app.shipment s
  );
 
  
===========================================================================================================================================================
 ---------------------------------------------------------------------------------------------------------------------------------------------------------   
   
CREATE OR REPLACE FUNCTION app.generator_kode_pengiriman()
RETURNS CHAR(8)
LANGUAGE plpgsql
AS $function$
DECLARE
    last_id INT;
    new_id CHAR(8);
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(kode_pengiriman FROM 7) AS INT)), 0)
    INTO last_id
    FROM final_task_kalbe_rakamin.app.shipment
    WHERE LEFT(kode_pengiriman, 6) = TO_CHAR(NOW(), 'YYMMDD');

    new_id := TO_CHAR(NOW(), 'YYMMDD') || LPAD((last_id + 1)::TEXT, 2, '0');
    
    RETURN new_id;
END;
$function$;

-- Menghapus default yang ada (jika ada)
ALTER TABLE final_task_kalbe_rakamin.app.shipment
ALTER COLUMN kode_pengiriman DROP DEFAULT;

-- Menambahkan default baru dari fungsi generator_kode_pengiriman
ALTER TABLE final_task_kalbe_rakamin.app.shipment
ALTER COLUMN kode_pengiriman SET DEFAULT app.generator_kode_pengiriman();


-- Masukkan data ke dalam tabel shipment dan isi kolom kode_pengiriman dengan hasil dari fungsi
INSERT INTO final_task_kalbe_rakamin.app.shipment (shipment_id, product_id, store_id, sending_time, driver_id, receiver, kode_pengiriman)
VALUES ( app.generator_kode_pengiriman());


=========================================================================================================================================================================
-------------------------------------------------------------------------------------------------------------------------------------------------------------


--Create Prosedurs

CREATE OR REPLACE PROCEDURE app.create_new_shipment(
  IN product_id INT,
  IN store_id INT,
  IN sending_time TIMESTAMPTZ,
  IN driver_id INT,
  IN receiver VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
  shipment_code CHAR(8);
BEGIN
  shipment_code := app.generator_kode_pengiriman();
  INSERT INTO app.shipment (product_id, store_id, sending_time, driver_id, receiver, kode_pengiriman)
  VALUES (product_id, store_id, sending_time, driver_id, receiver, shipment_code);
END;
$$;




CREATE OR REPLACE PROCEDURE app.add_product_to_shipment_2(
    IN product_id INT,
    IN store_id INT,
    IN driver_id INT,
    IN receiver CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Mendapatkan kode pengiriman menggunakan fungsi yang telah dibuat
    DECLARE
        kode_pengiriman CHAR(8);
    BEGIN
        SELECT app.kode_pengiriman() INTO kode_pengiriman;
    END;

    -- Insert ke dalam tabel shipment
    INSERT INTO app."shipment" (product_id, store_id, sending_time, driver_id, receiver, kode_pengiriman)
    VALUES (product_id, store_id, NOW(), driver_id, receiver, kode_pengiriman);

    -- Commit transaksi
    COMMIT;
END;
$$;
ALTER PROCEDURE app.add_product_to_shipment_2(INT, INT, INT, CHARACTER VARYING)
OWNER TO postgres;

-- Menambahkan data ke dalam tabel "shipment" dengan shipment_id dimulai dari 15
INSERT INTO app."shipment" (shipment_id, product_id, store_id, sending_time, driver_id, receiver, kode_pengiriman)
VALUES 
    (15, 15, 1, NOW(), 1, 'Wulan', app.kode_pengiriman()),
    (16, 16, 2, NOW(), 2, 'Limerence', app.kode_pengiriman()),
    (17, 17, 3, NOW(), 3, 'Aslan', app.kode_pengiriman());

-- Melakukan commit transaksi
COMMIT;



================================================================================================================================================
----------------------------------------------------------------------------------------------------------------------------------------------------------