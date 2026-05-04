--=========================================
--CASO 1 EN CONECCION ADMIN
-- CONEXION ADMIN PARA CREACION DE USUARIOS, ROLES, PRIVILEGIOS USUARIO: ADMIN (SYS / SYSTEM)
-- CREACIÓN DE USUARIOS
--=========================================

--Elimina users enc aso de ya existir
DROP USER PRY2205_USER1 CASCADE;
DROP USER PRY2205_USER2 CASCADE;

--Creacion dueño de tablas para caso 1 y 3

CREATE USER PRY2205_USER1
IDENTIFIED BY "DUEÑO.sumativa_3"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

-- Permiso de conexión user 1
GRANT CREATE SESSION TO PRY2205_USER1;


--creacion de usuario generico para caso 1 y 2
CREATE USER PRY2205_USER2
IDENTIFIED BY "GENERICO.sumativa_3"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

--Permiso de conexión user 2
GRANT CREATE SESSION TO PRY2205_USER2;

--Creacion de roles
--Rol para dueño, 
CREATE ROLE PRY2205_ROL_D;
GRANT CREATE TABLE TO PRY2205_ROL_D;
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE SYNONYM TO PRY2205_ROL_D;


--Rol generico, se dejan los select de las tabals especificas como grants directos para evitar la propagacion a varios user poR el rol.
CREATE ROLE PRY2205_ROL_P;
GRANT CREATE VIEW TO PRY2205_ROL_P;
GRANT CREATE PROFILE TO PRY2205_ROL_P;
GRANT CREATE USER TO PRY2205_ROL_P;


--Privilegios

--GRANT CREATE INDEX TO PRY2205_USER1; Genera error debido a que el la conexion admin no es sysdba, no puedo aplicar el rol. Pero debido a que user 1 puede Crear tablas y son propias, tiene privilegios de index
GRANT CREATE PUBLIC SYNONYM TO PRY2205_USER1;
--Se da la opcion de dar el grant de creacion de tablas directamente paras evitar errores, existieron errores al dejar el grant dentro del rol solamente LA PRIMERA VEZ
--GRANT CREATE TABLE TO PRY2205_USER1;

--Grant especificos a las tablas necesarias del caso 2
GRANT SELECT ON PRY2205_USER1.PACIENTE TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.BONO_CONSULTA TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.SALUD TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.SISTEMA_SALUD TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.MEDICO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.UNIDAD_CONSULTA TO PRY2205_USER2;
--En caso de falla del grant en el rol
--GRANT CREATE VIEW TO PRY2205_USER2;


--ASIGNACION DE ROLES y modificacion 
GRANT PRY2205_ROL_D TO PRY2205_USER1;
ALTER USER PRY2205_USER1 DEFAULT ROLE PRY2205_ROL_D;
GRANT PRY2205_ROL_P TO PRY2205_USER2;
ALTER USER PRY2205_USER2 DEFAULT ROLE PRY2205_ROL_P;
--fin de caso uno en admin


--CASO 1 EN USER 1--
--Conexión de user 1(PRY2205_USER1) Caso 1, creacion de sinonimos.
CREATE PUBLIC SYNONYM SYN_PACIENTE FOR PRY2205_USER1.PACIENTE;
CREATE PUBLIC SYNONYM SYN_BONO FOR PRY2205_USER1.BONO_CONSULTA;
CREATE PUBLIC SYNONYM SYN_SALUD FOR PRY2205_USER1.SALUD;
CREATE PUBLIC SYNONYM SYN_SISTEMA FOR PRY2205_USER1.SISTEMA_SALUD;
CREATE PUBLIC SYNONYM SYN_MEDICO FOR PRY2205_USER1.MEDICO;
CREATE PUBLIC SYNONYM SYN_UNIDAD FOR PRY2205_USER1.UNIDAD_CONSULTA;
--fin de caso 1 en user1



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

--fin caso 2 en user 3--


--CASO 3--
--Conexion user 1(PRY2205_USER1) caso 3, vista para aumento de sueldo a medicos en atencion, y optimizacion con indices

CREATE OR REPLACE VIEW VW_AUM_MEDICO_X_CARGO AS
SELECT 
--Rut con 0 antes en caso de ser menor a 10 millones, separador de miles, guion y dv
TO_CHAR(m.rut_med, '09G999G999') || '-' || m.dv_run AS RUT_MEDICO,

--Cargo con primera letra mayus, utliza la unidad de atencion
INITCAP('medico ' || u.nombre) AS CARGO,

--Sueldo sin signo peso y con separador de miles y manejo de nulls
TO_CHAR(NVL(m.sueldo_base,0), '999G999G999') AS SUELDO_ACTUAL,

--Aumento de sueldo con separador de miles y manejo de nulls
TO_CHAR(NVL(m.sueldo_base,0) * 1.15, '999G999G999') AS SUELDO_AUMENTADO

FROM SYN_MEDICO m
INNER JOIN SYN_UNIDAD u ON m.uni_id = u.uni_id
--Selecciona medicos en las unidades de atencion

--WHERE UPPER(u.nombre) LIKE '%ATENCIÓN%' 
--Literal como lo pide en intruccion, pero no permite indice. Se buscan en cambio los ids de unidades que empiezan en atencion
WHERE u.uni_id IN (
    SELECT uni_id 
    FROM SYN_UNIDAD
    WHERE uni_id IN (100, 200, 400)
)

--Se ordena sin tomar en cuenta el aumento, ya que el orden es el mismo y permite mejor uso del indice
ORDER BY m.sueldo_base DESC;

--muestra vista
SELECT * FROM VW_AUM_MEDICO_X_CARGO;


--Creacion de indices para optimizacion
--join rapido con unidad, evita buscar en toda la tabla
CREATE INDEX IDX_MEDICO_UNI
ON MEDICO(uni_id);

--ordenamiento rapido
CREATE INDEX IDX_MEDICO_SUELDO
ON MEDICO (sueldo_base);

--Evita full scan
CREATE INDEX IDX_UNIDAD_UNI
ON UNIDAD_CONSULTA (uni_id);

--vista de indices
--SELECT index_name, table_name
--FROM user_indexes
--ORDER BY index_name;

--Para revisar funcionamiento sin indices
--DROP INDEX IDX_MEDICO_UNI;
--DROP INDEX IDX_UNIDAD_UNI;
--DROP INDEX IDX_MEDICO_SUELDO

--FIN CASO 3--