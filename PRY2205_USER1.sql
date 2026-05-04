--CASO 1 EN USER 1--
--Conexión de user 1(PRY2205_USER1) Caso 1, creacion de sinonimos.
CREATE PUBLIC SYNONYM SYN_PACIENTE FOR PRY2205_USER1.PACIENTE;
CREATE PUBLIC SYNONYM SYN_BONO FOR PRY2205_USER1.BONO_CONSULTA;
CREATE PUBLIC SYNONYM SYN_SALUD FOR PRY2205_USER1.SALUD;
CREATE PUBLIC SYNONYM SYN_SISTEMA FOR PRY2205_USER1.SISTEMA_SALUD;
CREATE PUBLIC SYNONYM SYN_MEDICO FOR PRY2205_USER1.MEDICO;
CREATE PUBLIC SYNONYM SYN_UNIDAD FOR PRY2205_USER1.UNIDAD_CONSULTA;



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