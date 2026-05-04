--=========================================
--CASO 1 EN CONECCION ADMIN
-- CONEXION ADMIN PARA CREACION DE USUARIOS, ROLES, PRIVILEGIOS USUARIO: ADMIN


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

