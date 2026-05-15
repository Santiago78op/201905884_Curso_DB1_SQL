CREATE TABLE COUNTRY (
    ID          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NAME        VARCHAR(255) NOT NULL UNIQUE,
    CONTINENT   VARCHAR(255) NOT NULL,
    AREA        INTEGER NOT NULL,
    POPULATION  INTEGER NOT NULL,
    GDP         INTEGER
);

-- Lista el nombre y los continentes de los países en los continentes que contienen a Belize o Belgium
SELECT 
    NAME AS NOMBRE_PAIS,
    CONTINENT AS NOMBRE_CONTINENTE
FROM COUNTRY
WHERE CONTINENT IN (
    SELECT DISTINCT CONTINENT
    FROM COUNTRY
    WHERE NAME IN ('Belize', 'Belgium')
);

-- Países que tienen un GDP (Producto interno Bruto) mayor a TODOS los países de Europa.
SELECT
    NAME AS NOMBRE_PAIS,
    CONTINENT AS NOMBRE_CONTINENTE,
    GDP AS PIB
FROM COUNTRY
WHERE GDP > (
    SELECT MAX(GDP)
    FROM COUNTRY
    WHERE CONTINENT = 'Europe'
);

--- Países mayor area por continente. Desplegar el continente, el nombre del país y su área.
SELECT 
    CONTINENT AS NOMBRE_CONTINENTE,
    NAME AS NOMBRE_PAIS,
    AREA AS AREA
FROM COUNTRY c1
WHERE AREA = (
    SELECT MAX(AREA)
    FROM COUNTRY c2
    WHERE c2.CONTINENT = c1.CONTINENT
);

-- Encuentra cada pais que pertenezca a un continente en donde las poblaciones de todos los paises de ese continente sean menores a 25 millones.
SELECT 
    NAME AS NOMBRE_PAIS,
    CONTINENT AS NOMBRE_CONTINENTE,
    POPULATION AS POBLACION
FROM COUNTRY
WHERE CONTINENT IN (
    SELECT CONTINENT
    FROM COUNTRY
    GROUP BY CONTINENT
    HAVING MAX(POPULATION) < 25000000
);

-- Algunos paises tienen poblaciones mayores a 3 veces las poblaciones del cualquiera de los otros paises del mismo continente. Encuentra el nombre del pais, su continente y su población.
SELECT 
    NAME AS NOMBRE_PAIS,
    CONTINENT AS NOMBRE_CONTINENTE,
    POPULATION AS POBLACION
FROM COUNTRY c1
WHERE POPULATION > 3 * (
    SELECT MAX(POPULATION)
    FROM COUNTRY c2
    WHERE c2.CONTINENT = c1.CONTINENT
    AND c2.NAME <> c1.NAME
);
