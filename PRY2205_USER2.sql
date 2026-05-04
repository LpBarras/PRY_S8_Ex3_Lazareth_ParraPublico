
--CASO 2--
--Conexión de user 2 (PRY2205_USER2) Caso 2, creacion de vista 

CREATE OR REPLACE VIEW VW_RECALCULO_COSTOS AS
SELECT 
--Se muestra el rut con separador de miles, guion y digito verificador
TO_CHAR(p.pac_run, '99G999G999') || '-' || p.dv_run AS RUT_PACIENTE,

--Apellido paterno, materno y primer nombre todo en mayusculas
UPPER(p.apaterno || ' ' || p.amaterno || ' ' || p.pnombre) AS NOMBRE_PACIENTE,

--Sistema de salud con la primera letra en mayuscula, corresponde a descripcion en salud
INITCAP(sa.descripcion) AS SISTEMA_SALUD,

--Costo de la consulta con signo peso y separador de miles
TO_CHAR(NVL(b.costo,0), '$999G999G999') AS COSTO,

--Hora de atencion
b.hr_consulta AS HORARIO_ATENCION,

--Fecha en formato MM-AAAA
TO_CHAR(b.fecha_bono, 'MM-YYYY') AS FECHA_CONSULTA,

--Aplica reajuste del 15% cuando el costo fue entre 15000 y 25000, lo muestra con signo peso y separador de miles
TO_CHAR(
    CASE 
    WHEN NVL(b.costo,0) BETWEEN 15000 AND 25000 THEN b.costo * 1.15
    WHEN NVL(b.costo,0) > 25000 THEN b.costo * 1.20
    ELSE NVL(b.costo,0)
END
, '$999G999G999') AS REAJUSTE

--Se usan solo sinonimos
FROM SYN_BONO b
INNER JOIN SYN_PACIENTE p ON b.pac_run = p.pac_run
INNER JOIN SYN_SALUD sa ON p.sal_id = sa.sal_id
INNER JOIN SYN_SISTEMA s ON sa.tipo_sal_id = s.tipo_sal_id
--Se seleccionan consultas del años anterior al actual y despues de las 17:15
WHERE 
b.fecha_bono BETWEEN 
    TO_DATE('01-01-' || TO_CHAR(ADD_MONTHS(SYSDATE,-12),'YYYY'),'DD-MM-YYYY')
AND 
    TO_DATE('31-12-' || TO_CHAR(ADD_MONTHS(SYSDATE,-12),'YYYY'),'DD-MM-YYYY')

AND b.hr_consulta > '17:15'
--Paciente en fonasa o isapre
AND s.descripcion IN (
    SELECT descripcion 
    FROM SYN_SISTEMA
    WHERE UPPER(descripcion) IN ('FONASA','ISAPRE')
)
--ordenado por fecha y rut
ORDER BY b.fecha_bono, p.pac_run;

--Se muestra vista
SELECT * FROM VW_RECALCULO_COSTOS;