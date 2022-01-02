-- Вариант 2

-- 6. Создать два индекса для заданных таблиц по заданным полям. 
--    Одно задание – один индекс. Название индекса должно начитаться с префикса ”index_”:



-- 6.1. Таблица: Сотрудники. Атрибуты: ФИО

CREATE INDEX INDEX_EMPLOYEES ON EMPLOYEES (FULL_NAME);

-- 6.2. Таблица: Больничные_Листы. Атрибуты: ID_Болезни, ID_Сотрудника.

CREATE INDEX INDEX_SICK_LISTS ON SICK_LISTS (DESEASE_ID, EMP_ID);

-- 7. Создать пакет, состоящий из описанных процедур, функций и констант (если требуется). 
--    Все процедуры и функции при необходимости должны включать обработчики исключений.
--    Названия функций: F_<имя>. Формат названий процедур: P_<имя>. 
--    Написать анонимные блоки или запросы для проверки работы процедур и функций.

CREATE OR REPLACE PACKAGE PAC
AS
	FUNCTION F_LISTSCOUNT(EMP_ID_ NUMBER, DATE_START IN DATE, DATE_END IN DATE) RETURN NUMBER;
	FUNCTION F_AVG(EMP_ID_ NUMBER, DATE_START DATE := NULL, DATE_END DATE := NULL) RETURN NUMBER;
	PROCEDURE P_SICKLIST(DATE_ DATE);
	PROCEDURE P_COPY(EMP_ID_ NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY PAC
AS

-- 7.1. Написать функцию, которая возвращает число больничных листов, выписанных сотруднику за заданный период (Табельный номер и промежуток времени – параметры функции). 
--      Если промежуток времени не указан, считается количество за всё время.

FUNCTION F_LISTSCOUNT(EMP_ID_ NUMBER, DATE_START IN DATE, DATE_END IN DATE)
RETURN NUMBER
AS
	NUMBER_LISTS NUMBER(10);
	ID_VALID NUMBER(10);
BEGIN
	SELECT COUNT(*)
	INTO ID_VALID
	FROM EMPLOYEES EMP
	WHERE EMP.EMP_ID = EMP_ID_;

	IF ID_VALID = 0 THEN
		RAISE_APPLICATION_ERROR(-20000, 'Введен некорректный табельный номер.');
	END IF;

	SELECT COUNT(*)
	INTO NUMBER_LISTS
	FROM SICK_LISTS SL
	WHERE SL.EMP_ID = EMP_ID_
		AND (DATE_START IS NULL OR SL.START_DATE >= DATE_START)
		AND (DATE_END IS NULL OR SL.START_DATE <= DATE_END);

	RETURN NUMBER_LISTS;
END;

-- 7.2. Написать функцию, которая для заданного сотрудника возвращает среднюю продолжительность больничного в днях. 
--      Значение может рассчитываться за конкретный период. 
--      Период расчёта может быть не задан или задан частично. 
--      Функция имеет три аргумента: табельный номер, начало периода (с точностью до дня), окончание периода (с точность до дня). Только первый аргумент является обязательным. Предусмотреть вариант вызова функции без необязательных аргументов.


FUNCTION F_AVG(EMP_ID_ NUMBER, DATE_START IN DATE, DATE_END IN DATE)
RETURN NUMBER
AS
	AVG_LEN NUMBER(10);
	ID_VALID NUMBER(10);
BEGIN
	SELECT COUNT(*)
	INTO ID_VALID
	FROM EMPLOYEES EMP
	WHERE EMP.EMP_ID = EMP_ID_;

	IF ID_VALID = 0 THEN
		RAISE_APPLICATION_ERROR(-20000, 'Введен некорректный табельный номер.');
	END IF;

	SELECT AVG(NVL(LEAST(SL.START_DATE + SL.INTERV, DATE_END), SL.START_DATE + SL.INTERV) - NVL(GREATEST(SL.START_DATE, DATE_START), SL.START_DATE))
	INTO AVG_LEN
	FROM SICK_LISTS SL
	WHERE SL.EMP_ID = EMP_ID_
		AND (DATE_START IS NULL OR SL.START_DATE + SL.INTERV >= TRUNC(DATE_START, 'dd'))
		AND (DATE_END IS NULL OR SL.START_DATE <= TRUNC(DATE_END, 'dd'));

	RETURN AVG_LEN;
END;


-- 7.3. Написать процедуру, которая формирует список сотрудников болевших в течение года (Год – аргументы функции). 
--      Формат вывода: Табельный номер и ФИО сотрудника: список болезней. Формат вывода:
-- ------------------------------------------------------
--      Список сотрудников, болевших в течение <год> года:
--      <ФИО сотрудника 1>:
--          1. <болезнь 1>, <продолжительность в днях> дней;
--          <и т.д.>….
--      <ФИО сотрудника 2, не бравшего больничных>: не брал больничных;
--      <и т.д.>….
-- ------------------------------------------------------
 
PROCEDURE P_SICKLIST(DATE_ DATE)
AS
	EMP_ID_PREV NUMBER(10);
	NUMB NUMBER(10);

	CURSOR SICK_CURSOR IS
	SELECT EMP.EMP_ID, EMP.FULL_NAME AS EMP_NAME, DES.NAME AS DES_NAME
		, NVL(EXTRACT(DAY FROM SL.INTERV), TRUNC(SYSDATE - SL.START_DATE)) AS INTERV
		, CASE WHEN NVL(SL.START_DATE + SL.INTERV, SYSDATE) >= TRUNC(DATE_, 'YYYY') AND TRUNC(SL.START_DATE, 'YYYY') <= TRUNC(DATE_, 'YYYY') THEN '1' END AS MARK
		, MAX(CASE WHEN NVL(SL.START_DATE + SL.INTERV, SYSDATE) >= TRUNC(DATE_, 'YYYY') AND TRUNC(SL.START_DATE, 'YYYY') <= TRUNC(DATE_, 'YYYY') THEN '1' END) OVER (PARTITION BY EMP.EMP_ID) AS MARK2
	FROM EMPLOYEES EMP
		LEFT JOIN SICK_LISTS SL ON SL.EMP_ID = EMP.EMP_ID
		LEFT JOIN DESEASES DES ON DES.DESEASE_ID = SL.DESEASE_ID
	ORDER BY EMP.EMP_ID;
BEGIN
	if date_ is null THEN
		DBMS_OUTPUT.PUT_LINE('Введена некорректная дата.');
		return;
	end if;

	DBMS_OUTPUT.PUT_LINE('Список сотрудников, болевших в течение '|| TO_CHAR(DATE_, 'yyyy') ||' года:');
	FOR I IN SICK_CURSOR LOOP
		IF EMP_ID_PREV IS NULL OR EMP_ID_PREV != I.EMP_ID THEN
			EMP_ID_PREV := I.EMP_ID;
			NUMB := 0; 
			IF I.MARK2 IS NOT NULL THEN
				DBMS_OUTPUT.PUT_LINE(I.EMP_NAME || ':');
			ELSE
				DBMS_OUTPUT.PUT_LINE(I.EMP_NAME || ': не брал больничных;');
			END IF;
		END IF;
		IF I.MARK IS NOT NULL THEN
		    NUMB := NUMB + 1;
		    DBMS_OUTPUT.PUT_LINE(NUMB || '. '|| I.DES_NAME || ', ' || I.INTERV || ';');
		END IF;
	END LOOP;
END;



-- 7.4. Написать процедуру, которая выполняет копирование всех данных об указанном сотруднике, включая больничные листы и надбавки.
--      Аргумент процедуры - табельный номер. Для скопированной записи ставится отметка “копия” в поле ФИО.

PROCEDURE P_COPY(EMP_ID_ NUMBER)
AS
	CHECK_ID_VALID NUMBER(10);
	COPY_EMP_ID NUMBER(10);
	COPY_SICK_ID NUMBER(10);

	CURSOR SICK_CURSOR IS
	SELECT *
	FROM SICK_LISTS SL
	WHERE SL.EMP_ID = EMP_ID_;
BEGIN
	SELECT COUNT(*)
	INTO CHECK_ID_VALID
	FROM EMPLOYEES EMP
	WHERE EMP.EMP_ID = EMP_ID_;

	IF CHECK_ID_VALID = 0 THEN
		RAISE_APPLICATION_ERROR(-20000, 'Введен некорректный id_сотрудника.');
	END IF;

	SELECT MAX(EMP.EMP_ID) + 1
	INTO COPY_EMP_ID
	FROM EMPLOYEES EMP;

	INSERT INTO EMPLOYEES (EMP_ID, FULL_NAME, ADDRESS, POST, SALARY, BIRTHDAY)
	SELECT COPY_EMP_ID, EMP.FULL_NAME || ' копия', EMP.ADDRESS, EMP.POST, EMP.SALARY, EMP.BIRTHDAY
	FROM EMPLOYEES EMP
	WHERE EMP.EMP_ID = EMP_ID_;

	SELECT MAX(LIST_ID)
	INTO COPY_SICK_ID
	FROM SICK_LISTS;

	FOR I IN SICK_CURSOR LOOP
		COPY_SICK_ID := COPY_SICK_ID + 1;

		INSERT INTO SICK_LISTS (LIST_ID,START_DATE,INTERV,DESEASE_ID,EMP_ID)
		VALUES (COPY_SICK_ID, I.START_DATE, I.INTERV, I.DESEASE_ID, COPY_EMP_ID);
	END LOOP;

	INSERT INTO EMP_ALLOWANCES (ALLOW_ID,EMP_ID)
	SELECT EA.ALLOW_ID, COPY_EMP_ID
	FROM EMP_ALLOWANCES EA
	WHERE EA.EMP_ID = EMP_ID_;

END;

END PAC;
/

SELECT FULL_NAME, PAC.F_LISTSCOUNT(EMP_ID, TO_DATE('2017-01', 'YYYY-MM'), TO_DATE('2020-12', 'YYYY-MM'))
FROM EMPLOYEES;
SELECT PAC.F_LISTSCOUNT(1, NULL, NULL)
FROM DUAL;
--------


SELECT FULL_NAME, PAC.F_AVG(EMP_ID, TO_DATE('2017-01-03', 'YYYY-MM-DD'), TO_DATE('2020-12-02', 'YYYY-MM-DD'))
FROM EMPLOYEES;
SELECT PAC.F_AVG(1)
FROM DUAL;

----------

BEGIN
	PAC.P_SICKLIST(TO_DATE('2020', 'YYYY'));
	PAC.P_SICKLIST(null);
END;
/
------
SAVEPOINT A;

SELECT * FROM EMPLOYEES;
SELECT * FROM SICK_LISTS;

BEGIN
	PAC.P_COPY(1);
END;
/
SELECT * FROM EMPLOYEES;
SELECT * FROM SICK_LISTS;
SELECT * FROM EMP_ALLOWANCES;

ROLLBACK;




-- 8. Создать триггеры, включить обработчики исключений. Написать скрипты для проверки. 
--    При необходимости снять ограничения (если ограничение мешает проверить работу триггера).



-- 8.1. Написать триггер, который активизируются при изменении содержимого таблицы «Сотрудники» и проверяющий, 
--      чтобы указанное значение оклада не выходило за определённые границы. 
--      Значение границ оформить как константы. 
--      Для должностей из определенного списка значение поля оклад должно заполняться автоматически из таблицы-справочника 
--      (в таблице должно быть два поля: должность и значение по умолчанию).

CREATE TABLE DIRECTORY 
(
	POST_ID NUMBER(10,0),
	POST_NAME  VARCHAR2(100),
	DEFAULT_SALARY NUMBER(10, 0),
    CONSTRAINT  PK_DIRECTORY PRIMARY KEY (POST_ID),
    CONSTRAINT CK_DIRECTORY_NOT_NULL CHECK (POST_NAME IS NOT NULL AND DEFAULT_SALARY IS NOT NULL)
);


INSERT INTO DIRECTORY(POST_ID, POST_NAME, DEFAULT_SALARY) VALUES(1, 'врач-невролог', 50000);
INSERT INTO DIRECTORY(POST_ID, POST_NAME, DEFAULT_SALARY) VALUES(2, 'врач клинической лабораторной диагностики', 50000);
INSERT INTO DIRECTORY(POST_ID, POST_NAME, DEFAULT_SALARY) VALUES(3, 'врач функциональной диагностики', 25000);
INSERT INTO DIRECTORY(POST_ID, POST_NAME, DEFAULT_SALARY) VALUES(4, 'врач-анестезиолог-реаниматолог', 25000);

CREATE OR REPLACE TRIGGER T_SALARY
BEFORE
UPDATE
ON EMPLOYEES
FOR EACH ROW
DECLARE
	MIN_SALARY CONSTANT NUMBER := 10000;
	MAX_SALARY CONSTANT NUMBER := 100000;
	DEFAULT_DEFAULT_SALARY CONSTANT NUMBER := 50000;
BEGIN
	IF :NEW.SALARY > MAX_SALARY OR :NEW.SALARY < MIN_SALARY THEN
		SELECT NVL(MAX(DIR.DEFAULT_SALARY), DEFAULT_DEFAULT_SALARY)
		INTO :NEW.SALARY
		FROM DIRECTORY DIR
		WHERE DIR.POST_NAME = :NEW.POST;
	END IF;
END;
/
SAVEPOINT A;

UPDATE EMPLOYEES SET SALARY = 10005
WHERE EMP_ID = 3;

UPDATE EMPLOYEES SET SALARY = 1000000
WHERE EMP_ID = 1;

UPDATE EMPLOYEES SET POST = 'Медсестра'
WHERE EMP_ID = 2;

UPDATE EMPLOYEES SET SALARY = 60000000
WHERE EMP_ID = 2;

SELECT * FROM EMPLOYEES;

ROLLBACK;

-- 8.2. Написать триггер, сохраняющий статистику изменений таблицы «Сотрудники» в таблице «Сотрудники_Статистика». 
--      В таблице «Сотрудники_Статистика» хранятся дата изменения, тип изменения (insert, update, delete). 
--      Триггер также выводит на экран сообщение с указанием количества дней прошедших со дня последнего изменения.

CREATE TABLE EMPLOYEES_STATISTICS
(
	ID NUMBER(10),
	CHANGE_DATE DATE,
	CHANGE_TYPE VARCHAR2(10),
	CONSTRAINT PK_EMPLOYEES_STATISTICS PRIMARY KEY (ID),
	CONSTRAINT CH_EMPLOYEES_STATISTICS CHECK (CHANGE_DATE IS NOT NULL AND CHANGE_TYPE IS NOT NULL)
);

CREATE OR REPLACE TRIGGER T_STATISTIC
AFTER
INSERT OR UPDATE OR DELETE
ON EMPLOYEES
FOR EACH ROW
DECLARE
	LAST_ID NUMBER(10);
	LAST_CHANGE_DATE DATE;
	CHANGE_TYPE VARCHAR2(10);
BEGIN
	SELECT MAX(ES.ID), MAX(ES.CHANGE_DATE)
	INTO LAST_ID, LAST_CHANGE_DATE
	FROM EMPLOYEES_STATISTICS ES;

	IF INSERTING THEN
		CHANGE_TYPE := 'INSERT';
	ELSIF DELETING THEN
		CHANGE_TYPE := 'DELETE';
	ELSE
		CHANGE_TYPE := 'UPDATE';
	END IF;

	IF LAST_CHANGE_DATE IS NOT NULL THEN
		DBMS_OUTPUT.PUT_LINE('Дней с момента последнего изменения: ' || TRUNC(SYSDATE - LAST_CHANGE_DATE) || '.');
	END IF;

	INSERT INTO EMPLOYEES_STATISTICS (ID, CHANGE_DATE, CHANGE_TYPE)
	VALUES (NVL(LAST_ID + 1, 1), SYSDATE, CHANGE_TYPE);
END;
/
SAVEPOINT A;
INSERT INTO EMPLOYEES_STATISTICS (ID, CHANGE_DATE, CHANGE_TYPE) VALUES (1, TO_DATE('2020-12-20', 'YYYY-MM-DD'), 'INSERT');

INSERT INTO EMPLOYEES (EMP_ID, FULL_NAME, ADDRESS, POST, SALARY, BIRTHDAY) VALUES (6, 'Николай', 'Ленина 35', 'Бухгалтер', 1000000, TO_DATE('2020-10-23 06:05:55', 'YYYY-MM-DD HH24:MI:SS'));
UPDATE EMPLOYEES EMP SET EMP.SALARY = EMP.SALARY * 0.8 WHERE EMP.EMP_ID = 6;
DELETE EMPLOYEES EMP WHERE EMP.EMP_ID = 6;

SELECT * FROM EMPLOYEES_STATISTICS;


ROLLBACK;



-- 8.3. Написать триггер, активизирующийся при вставке в таблицу “Надбавки” и проверяющий наличие надбавки с указанным наименованием.
--      Если такая набавка уже существует, вместо вставки обновляет значение суммы.

CREATE VIEW ALLOW_VIEW AS
SELECT * FROM ALLOWANCES;


CREATE OR REPLACE TRIGGER T_ALLOW
INSTEAD OF
INSERT
ON ALLOW_VIEW
FOR EACH ROW
DECLARE
	EXISTING_ALLOW_ID NUMBER(10);
BEGIN
	SELECT MIN(AL.ALLOW_ID)
	INTO EXISTING_ALLOW_ID
	FROM ALLOWANCES AL
	WHERE LOWER(AL.NAME) = LOWER(:NEW.NAME);

	IF EXISTING_ALLOW_ID IS NULL THEN
		INSERT INTO ALLOWANCES (ALLOW_ID, NAME, AMOUNT)
		VALUES (:NEW.ALLOW_ID, :NEW.NAME, :NEW.AMOUNT);
	ELSE
		UPDATE ALLOWANCES AL
		SET AL.AMOUNT = :NEW.AMOUNT
		WHERE AL.ALLOW_ID = EXISTING_ALLOW_ID;
	END IF;
END;
/
SAVEPOINT A;

INSERT INTO ALLOW_VIEW (ALLOW_ID, NAME, AMOUNT) VALUES (11, 'За труд', 10000);
INSERT INTO ALLOW_VIEW (ALLOW_ID, NAME, AMOUNT) VALUES (12, 'За труд', 20000);

SELECT * FROM ALLOWANCES WHERE NAME = 'За труд';

ROLLBACK;



DROP TABLE DIRECTORY;
DROP TABLE EMPLOYEES_STATISTICS;
DROP PACKAGE PAC;
DROP TRIGGER T_ALLOW;
DROP TRIGGER T_STATISTIC;
DROP TRIGGER T_SALARY;
DROP VIEW ALLOW_VIEW;
DROP INDEX INDEX_EMPLOYEES;
DROP INDEX INDEX_SICK_LISTS;
