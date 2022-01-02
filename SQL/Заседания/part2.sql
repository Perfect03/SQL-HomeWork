/* Индивидуальная работа часть 2
   Поданева А.Н. гр. 931923
   Вариант 6   
   SQL: [PosgresSQL] */

/*6. Создать два индекса для заданных таблиц по заданным полям. Одно задание – один индекс. Название индекса должно начитаться с префикса ”index_”:*/

-- 6.1. Таблица: Члены_городского_совета. Атрибуты: ФИО.

CREATE INDEX index_peoples ON "Члены городского совета" ("ФИО");

SELECT "ФИО" FROM "Члены городского совета";

-- 6.2. Таблица: Заседания. Атрибуты: ID_Комиссии, ID_Ответственного.

CREATE INDEX index_meetings ON "Заседания" ("ID Комиссии", "ID Ответственного");

SELECT "ID Комиссии", "ID Ответственного"
FROM "Заседания";

/*7. Написать процедуры и функции, согласно условиям . Все процедуры и функции при необходимости должны включать обработчики исключений.

Названия функций: F_<имя>. Формат названий процедур: P_<имя>. Написать анонимные блоки или запросы для проверки работы процедур и функций.*/

/* 7.1. Написать функцию, возвращающую количество комиссией, в которых участвует указанный член городского совета в течение определённого периода (id_члена городского совета и промежуток времени – аргументы функции). Период указывается с точностью до месяца. Если промежуток времени не указан, считается количество за всё время. /*

CREATE OR REPLACE FUNCTION F_ComCount(member__id INTEGER, date_start DATE DEFAULT NULL, date_end DATE DEFAULT NULL)
RETURNS INTEGER AS $$
DECLARE
member_valid INTEGER;
kol INTEGER;
BEGIN

	SELECT COUNT(*)
	INTO member_valid
	FROM "Члены городского совета"
	WHERE "Члены городского совета"."ID Члена ГС" = member__id;
	IF member_valid = 0
	THEN RAISE EXCEPTION 'Некорректный ID Члена ГС.';
	RETURN NULL; END IF;
	SELECT COUNT (DISTINCT "Заседания"."ID Комиссии")
	INTO kol
	FROM "Заседания"
		JOIN "Члены комиссии" ON "Члены комиссии"."ID Комиссии" = "Заседания"."ID Комиссии"
	WHERE "Члены комиссии"."ID Члена ГС" = member__id AND (date_start IS NULL OR to_char("Заседания"."Дата и время проведения", 'YYYY-MM') >= to_char(date_start, 'YYYY-MM')) AND (date_end IS NULL OR to_char("Заседания"."Дата и время проведения", 'YYYY-MM') <= to_char(date_end, 'YYYY-MM'));

	RETURN kol;
end; $$
LANGUAGE plpgsql;

/* 7.2. Написать функцию, которая для заданной комиссии рассчитывает общее количество заседаний, проведенных за указанный период времени.
-- Функция имеет три аргумента: id_комиссии, начало периода, окончание периода. Только первый аргумент является обязательным. Предусмотреть вариант вызова функции без необязательных аргументов.

-- members mr		члены городского совета
-- colleges cm		члены комиссии
-- commissions c		комиссии
-- meetings mt		заседания /*


CREATE OR REPLACE FUNCTION F_MetCount(comission__id IN integer, date_start DATE, date_end DATE)
RETURNS INTEGER AS $$
DECLARE
comission_valid INTEGER;
kol INTEGER;
BEGIN

	SELECT COUNT(*)
	INTO comission_valid
	FROM "Комиссии"
	WHERE "Комиссии"."ID Комиссии" = comission__id;
	IF comission_valid = 0
	THEN RAISE EXCEPTION 'Некорректный ID Комиссии.';
	RETURN NULL; END IF;
	SELECT COUNT (*)
	INTO kol
	FROM "Заседания"
	WHERE "Заседания"."ID Комиссии" = comission__id
		AND (date_start IS NULL OR "Заседания"."Дата и время проведения" >= date_start)
		AND (date_end IS NULL OR "Заседания"."Дата и время проведения" <= date_end);

	RETURN kol;
end; $$
LANGUAGE plpgsql;

/* 7.3. Написать процедуру, которая формирует календарь заседаний для заданного члена городского совета. (id_члена городского совета и год – параметры процедуры).
-- Формат вывода:
-- ------------------------------------------------------
-- Календарь заседаний для <ФИО> на <год> год:
-- <месяц_1>:
-- 1. <Дата и время проведения>. <Название комиссии> – <роль: член комиссии / ответственный секретарь>;
-- 2. <Дата и время проведения>. <Название комиссии> – <роль: член комиссии / ответственный секретарь>;
-- <и т.д.>
-- <месяц_2 (без заседаний)>: заседаний не запланировано
-- <и т.д.>
/*

CREATE OR REPLACE PROCEDURE P3_Calendar(member_id integer = null, cur_date VARCHAR = null)
AS $$
DECLARE
check_ integer;
num integer;
name_ VARCHAR;
res VARCHAR;
month_ integer;
temp1 VARCHAR;
cursor_ SCROLL CURSOR FOR
SELECT EXTRACT(month FROM "Заседания"."Дата и время проведения"),
to_char( "Заседания"."Дата и время проведения", 'yyyy-mm-dd hh24:mi') || '. '||"Комиссии"."Название" || ' - '|| 
CASE WHEN "Заседания"."ID Ответственного" = member_id THEN
'ответственный секретарь' ELSE 'член комиссии' END || ';'
FROM "Заседания"
JOIN "Члены комиссии" ON "Члены комиссии"."ID Комиссии" = "Заседания"."ID Комиссии"
JOIN "Комиссии" ON "Комиссии"."ID Комиссии" = "Заседания"."ID Комиссии"
WHERE "Члены комиссии"."ID Члена ГС" = member_id
AND to_char("Заседания"."Дата и время проведения", 'yyyy') = cur_date
ORDER BY "Заседания"."Дата и время проведения";

begin
IF member_id IS null AND cur_date IS null THEN
RAISE EXCEPTION 'Данные заданы некорректно';
END IF;

SELECT COUNT(*) INTO check_
FROM "Члены городского совета" WHERE "Члены городского совета"."ID Члена ГС" = member_id;

IF check_ = 0 THEN
RAISE EXCEPTION 'Участника с таким id не существует';
END IF;

SELECT "ФИО" INTO name_ FROM "Члены городского совета"
WHERE "ID Члена ГС" = member_id;

res = 'Календарь заседаний для ' || name_ || ' на ' || cur_date || ' год';
OPEN cursor_;
RAISE NOTICE '%', res;
FETCH cursor_ INTO month_, temp1;
FOR i in 1..12 LOOP
num= 0;
IF month_ = i THEN
res = to_char(to_timestamp (i::text, 'MM'), 'TMMonth ')||':';
RAISE NOTICE '%', res;
ELSE
res = to_char(to_timestamp (i::text, 'MM'), 'TMMonth ') || ': заседаний не запланировано';
RAISE NOTICE '%', res;
END IF; LOOP
EXIT WHEN NOT FOUND OR
month_ != i;
num = num + 1;
res = num ||' . ' ||temp1;
RAISE NOTICE '%', res;
FETCH cursor_ INTO month_, temp1;
END LOOP;
END LOOP;
CLOSE cursor_;
END;
$$
LANGUAGE plpgsql


CALL P3_Calendar(2, '2020');
CALL P3_Calendar(2, '2021');
CALL P3_Calendar(3, '2020');
CALL P3_Calendar(3, '2021');



/* 7.4. Написать процедуру, которая выполняете копирование всех данных о указанной комиссии, включая её состав. Аргумент процедуры - id_комиссии. Для скопированной записи ставится отметка "копия" в поле название.  /*

CREATE OR REPLACE PROCEDURE P_copy(com__id IN INTEGER)
AS $$
DECLARE
comission_valid INTEGER;
copy_comission_id INTEGER;

BEGIN
SELECT COUNT(*)
INTO comission_valid
FROM "Комиссии"
WHERE "Комиссии"."ID Комиссии" = com__id;

IF comission_valid = 0 THEN
RAISE EXCEPTION 'Введён некорректный ID Комиссии'; RETURN;
END IF;

SELECT MAX("Комиссии"."ID Комиссии") +1
INTO copy_comission_id
FROM "Комиссии";

INSERT INTO "Комиссии" ("ID Комиссии", "ID Председателя", "Название", "Бюджет") 
SELECT copy_comission_id, "Комиссии"."ID Председателя", "Комиссии"."Название" || ' копия', "Комиссии"."Бюджет"
FROM "Комиссии"
WHERE "Комиссии"."ID Комиссии" = com__id;

INSERT INTO "Члены комиссии" ("ID Члена ГС", "ID Комиссии") 
SELECT "Члены комиссии"."ID Члена ГС", copy_comission_id
FROM "Члены комиссии"
WHERE "Члены комиссии"."ID Комиссии" = com__id;

END;$$
LANGUAGE plpgsql;


/* 7.5. Написать один или несколько сценариев (анонимных блока) демонстрирующий работу процедур и функций из пп. 1-4. 
Требование:
- Включение в запрос (для функций)
- Для каждой процедуры не менее 3-х примеров работы с различными значениями аргументов.
- Комментарии для каждого сценария описывающие суть примера и результат. /*

-- 7.1:

--принадлежность полиса к указанному временному промежутку определял только по Дате начала - как сказано в условии задания 7.2.
SELECT F_ComCount(4);
SELECT F_ComCount(5);
SELECT F_ComCount(6);
SELECT F_ComCount(6, '2020-01-01', '2025-01-01');
SELECT F_ComCount(6, '2020-05-01', '2025-01-01');
SELECT F_ComCount(6, '2020-05-31', '2025-01-01');
SELECT F_ComCount(6, '2020-06-01', '2025-01-01');



-- 7.2:

SELECT F_MetCount(2, '1990-02-25', '2033-08-15');
SELECT F_MetCount(1, '1990-02-25', '2033-08-15');
SELECT F_MetCount(1, '2021-01-01', '2022-08-15');


-- 7.3:


-- 7.4:

CALL p_copy(1);

SELECT * FROM "Комиссии";
-- скопировалась комиссия "Палата №1"

SELECT * FROM "Члены комиссии";




/* 8. Создать триггеры, включить обработчики исключений. Написать скрипты для проверки. При необходимости снять ограничения (если
ограничение мешает проверить работу триггера). 

    8.1. Написать триггер, проверяющий, что дата в таблице "Заседания" не заполнена прошедшим числом (это не относится ко времени).
-- Если место не указано, то автоматически ставится место проведения последнего заседания./*


CREATE OR REPLACE VIEW meetings_view AS
SELECT * FROM "Заседания";
CREATE OR REPLACE FUNCTION F_MeetDate()
RETURNS TRIGGER AS $$
DECLARE
meet_count INTEGER;
new_adres VARCHAR;
err VARCHAR;
BEGIN
	IF to_char(new."Дата и время проведения", 'YYYY-MM-DD') < to_char(current_date, 'YYYY-MM-DD') THEN
	RAISE EXCEPTION 'Дата должна быть заполнена не прошедшим числом.';
	END IF;

	IF new."Место" IS NULL THEN
		WITH t AS
		(
			SELECT row_number() OVER (ORDER BY Current_timestamp - "Заседания"."Дата и время проведения") AS i,
			"Заседания"."Место" AS place
			, "Заседания"."Дата и время проведения"
			FROM "Заседания"
			WHERE "Заседания"."Дата и время проведения" <= current_date
		)
	SELECT place
	INTO new_adres
	FROM t
	WHERE i = 1;
	IF new_adres IS NULL THEN
	err='Укажите адрес';
		RAISE INFO '%',err;
	END IF;
	ELSE
		new_adres = new."Дата и время проведения";
	END IF;

	INSERT INTO "Заседания" ("ID Заседания", "ID Комиссии", "ID Ответственного", "Дата и время проведения", "Место")
	VALUES (new."ID Заседания", new."ID Комиссии", new."ID Ответственного", new."Дата и время проведения", new_adres); RETURN NEW;
END;$$
LANGUAGE plpgsql;


CREATE TRIGGER T_MeetDate
INSTEAD OF INSERT
ON meetings_view
FOR EACH ROW EXECUTE PROCEDURE F_MeetDate();



INSERT INTO meetings_view ("ID Заседания", "ID Комиссии", "ID Ответственного", "Дата и время проведения") VALUES (67,1,1, to_timestamp('2022-01-01 10:30:00', 'YYYY-MM-DD hh24:mi:ss'));
UPDATE "Заседания" SET "Место" = 'г. Новосибирск, Фрунзе, д.17, каб.16' WHERE "ID Заседания" = 1;
DELETE FROM "Заседания" WHERE "ID Заседания" = 2;

SELECT * FROM meetings_view



--Проверка вывода ошибки о дате:
INSERT INTO meetings_view ("ID Заседания", "ID Комиссии", "ID Ответственного", "Дата и время проведения") VALUES (83,1,1, to_timestamp('2021-01-01 10:30:00', 'YYYY-MM-DD hh24:mi:ss'));

--Проверка автоматического выставления места:
INSERT INTO meetings_view ("ID Заседания", "ID Комиссии", "ID Ответственного", "Дата и время проведения") VALUES (63,1,1, to_timestamp('2022-01-01 10:30:00', 'YYYY-MM-DD hh24:mi:ss'));

SELECT * FROM "Заседания";


/* 8.2. Написать триггер, сохраняющий статистику изменений таблицы "Заседания" в таблице "Заседания_Статистика", в которой хранится дата изменения, тип изменения (insert, update, delete).
-- Триггер также выводит на экран сообщение с указанием количества дней прошедших со дня последнего изменения./*

CREATE TABLE "Заседания статистика"
(
	id INTEGER,
	change_date DATE NOT NULL,
	change_type varchar(100) NOT NULL,
	CONSTRAINT pk_meetings_statistics PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION F_table_form()
RETURNS TRIGGER AS $$
DECLARE
last_id INTEGER;
last_change_date DATE;
change_type varchar(100);
str varchar(100);
BEGIN
SELECT MAX("Заседания статистика".id), MAX("Заседания статистика".change_date)
INTO last_id, last_change_date
FROM "Заседания статистика";
IF (TG_OP = 'INSERT') THEN change_type = 'insert';
ELSIF (TG_OP = 'DELETE') THEN change_type = 'delete';
ELSIF (TG_OP = 'UPDATE') THEN change_type = 'update';
END IF;

IF last_change_date IS NOT NULL THEN
str = 'Дней с момента последнего изменения: ' || CURRENT_DATE - last_change_date;
RAISE INFO '%',str;
END IF;

INSERT INTO "Заседания статистика" (id, change_date, change_type)
VALUES (COALESCE(last_id + 1, 1), current_date, change_type);
RETURN NEW; END; $$
LANGUAGE plpgsql;


CREATE TRIGGER TR_TableForm
AFTER
INSERT OR UPDATE OR DELETE
ON "Заседания"
FOR EACH ROW EXECUTE PROCEDURE F_table_form();


--ПРОВЕРКА:
INSERT INTO "Заседания" ("ID Заседания", "ID Комиссии", "ID Ответственного", "Дата и время проведения", "Место") VALUES (23,5,1, to_timestamp('2021-01-01 10:30:00', 'YYYY-MM-DD hh24:mi:ss'), 'г. Новосибирск, Фрунзе, д.99, каб.99');
UPDATE "Заседания" SET "Место" = 'г. Новосибирск, Фрунзе, д.17, каб.16' WHERE "ID Заседания" = 1;
DELETE FROM "Заседания" WHERE "ID Заседания" = 2;

SELECT * FROM "Заседания статистика"



/* 8.3. Написать триггер, который при вставке в таблицу "Комиссия" проверяет наличие комиссии с таким же названием. Если такая комиссия уже есть, то обновляется значение полей бюджет и председатель./*

CREATE OR REPLACE VIEW comissions_view AS
SELECT * FROM "Комиссии";
CREATE OR REPLACE FUNCTION F_InsCom()
RETURNS TRIGGER AS $$
DECLARE
	existing_comission_ID INTEGER;
BEGIN
	SELECT MIN("Комиссии"."ID Комиссии")
	INTO existing_comission_ID
	FROM "Комиссии"
	WHERE LOWER("Комиссии"."Название") = LOWER(NEW."Название");

	IF existing_comission_ID IS NULL THEN
		INSERT INTO "Комиссии" ("ID Комиссии", "ID Председателя", "Название", "Бюджет")
		VALUES (NEW."ID Комиссии", NEW."ID Председателя", NEW."Название", NEW."Бюджет");
	ELSE
		UPDATE "Комиссии"
		SET "Бюджет" = NEW."Бюджет"
		WHERE "ID Комиссии" = existing_comission_ID;
		UPDATE "Комиссии"
		SET "ID Председателя" = NEW."ID Председателя"
		WHERE "ID Комиссии" = existing_comission_ID;
	END IF;
	RETURN NEW;
END;$$
LANGUAGE plpgsql;

CREATE TRIGGER T_InsCom
INSTEAD OF
INSERT
ON comissions_view
FOR EACH ROW EXECUTE PROCEDURE F_InsCom();




--отсутствующая ранее комиссия:
INSERT INTO comissions_view("ID Комиссии", "ID Председателя", "Название", "Бюджет") VALUES 
(8, 7, 'Палата№3', 144);


--присутствующая ранее комиссия:
INSERT INTO comissions_view("ID Комиссии", "ID Председателя", "Название", "Бюджет") VALUES 
(8, 7, 'Избирательная', 14);

SELECT * FROM "Комиссии";



----------------------------------------------------------------------------------------
DROP FUNCTION F_ComCount;
DROP FUNCTION F_MetCount;
DROP PROCEDURE P_form;
DROP PROCEDURE P_copy;

DROP TRIGGER t_MeetDate ON meetings_view;
DROP FUNCTION F_MeetDate();

DROP TRIGGER TR_TableForm ON "Заседания";
DROP FUNCTION F_table_form();
DROP TABLE "Заседания статистика";

DROP TRIGGER T_InsCom ON comissions_view;
DROP FUNCTION F_InsCom;
DROP VIEW comissions_view;