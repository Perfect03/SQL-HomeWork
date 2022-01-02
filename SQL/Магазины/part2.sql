-- Вариант 5.

-- 6. Создать два индекса для заданных таблиц по заданным полям. Одно задание - один индекс. Название индекса должно начитаться с префикса "index_":

-- 6.1. Таблица: Поставщики. Атрибуты: Название.

create index index_suppliers on suppliers (name);

-- 6.2. Таблица: Товары. Атрибуты: Название, ID_Товара.

create index index_products on products (product_id, name);

-- 7. Создать пакет, состоящий из описанных процедур, функций и констант (если требуется). Все процедуры и функции при необходимости должны включать обработчики исключений.
-- Названия функций: F_<имя>. Формат названий процедур: P_<имя>.
-- Написать анонимные блоки или запросы для проверки работы процедур и функций.

create or replace package PAC
as
	function F_SuppliersCount(store_id_ number, date_ date := null) return number;
	function F_AvgCost(supplier_id_ number, date_ date := null, category_ varchar2 := null) return number;
	procedure P_List(product_name varchar2, date_ date);
	procedure P_Copy(store_id_ number);
end;
/
create or replace package body PAC
as

-- 7.1. Написать функцию, которая возвращает количество поставщиков для заданного магазина, выполнивших доставку в течение заданного года.
-- Если год не указан, считается количество за всё время.

function F_SuppliersCount(store_id_ number, date_ date)
return number
as
	store_valid number(10);
	suppliers_count number(10);
begin
	select count(*)
	into store_valid
	from stores s
	where s.store_id = store_id_;

	if store_valid = 0 then
		raise_application_error(-20000, 'Введен некорректный ID_магазина.');
	end if;

	select count(distinct ss.supplier_id)
	into suppliers_count
	from supplies ss
	where ss.store_id = store_id_
		and (date_ is null or trunc(ss.supply_date, 'yyyy') = trunc(date_, 'yyyy'));

	return suppliers_count;
end;

-- 7.2. Написать функцию, которая рассчитывает среднюю стоимость поставки для поставщика. Значение может рассчитываться за год и/или для определённой категории товаров.
-- Функция имеет три аргумента: id_поставщика, год и категория товара. Только первый аргумент является обязательным. Предусмотреть вариант вызова функции без необязательных аргументов.

function F_AvgCost(supplier_id_ number, date_ date, category_ varchar2)
return number
as
	supplier_valid number(10);
	avg_cost number(10, 2);
begin
	select count(*)
	into supplier_valid
	from suppliers sr
	where sr.supplier_id = supplier_id_;

	if supplier_valid = 0 then
		raise_application_error(-20000, 'Введен некорректный ID_поставщика.');
	end if;

	select avg(ss.cost)
	into avg_cost
	from supplies ss
		inner join products p on p.product_id = ss.product_id
	where ss.supplier_id = supplier_id_
		and (date_ is null or trunc(ss.supply_date, 'yyyy') = trunc(date_, 'yyyy'))
		and (category_ is null or lower(p.category) = lower(category_));

	return avg_cost;
end;

-- 7.3. Написать процедуру, которая формирует список поставщиков поставлявших конкретный товар в указанный месяц (Название товара и дата - аргументы процедуру).
-- Формат вывода:
-- ------------------------------------------------------
-- Список поставок <название товара> за <название месяца>:
-- <Название поставщика 1>, <телефон>:
-- 1. <дата поставки> - <Название магазина>
-- 2. <дата поставки> - <Название магазина>
-- и т.д.
-- <Название поставщика 2>, <телефон>:
-- 1. <дата поставки> - <Название магазина>
-- 2. <дата поставки> - <Название магазина>
-- и т.д.
-- ------------------------------------------------------

procedure P_List(product_name varchar2, date_ date)
as
	product_valid number(10);
	supplier_id_last number(10);
	num number(10);

	cursor supplies_cursor is
	select ss.supplier_id, sr.name as supplier_name, sr.phone, ss.supply_date, s.name as store_name
	from supplies ss
		inner join products p on p.product_id = ss.product_id
		inner join suppliers sr on sr.supplier_id = ss.supplier_id
		inner join stores s on s.store_id = ss.store_id
	where lower(p.name) = lower(product_name)
		and trunc(ss.supply_date, 'mm') = trunc(date_, 'mm')
	order by ss.supplier_id;
begin
	select count(*)
	into product_valid
	from products p
	where lower(p.name) = lower(product_name);

	if product_valid = 0 then
		dbms_output.put_line('Введено некорректное имя продкута.');
		return;
	end if;
	
	if date_ is null then
		dbms_output.put_line('Введите дату.');
		return;
	end if;

	dbms_output.put_line('Список поставок ' || product_name || ' за ' || trim(to_char(date_, 'month', 'nls_date_language=russian')) || ':');

	for i in supplies_cursor loop
		if supplier_id_last is null or supplier_id_last != i.supplier_id then
			supplier_id_last := i.supplier_id;
			num := 0;

			dbms_output.put_line(i.supplier_name || ', ' || i.phone);
		end if;

		num := num + 1;

		dbms_output.put_line(num || '. ' || to_char(i.supply_date, 'yyyy-mm-dd') || ' - ' || i.store_name);
	end loop;

	if supplier_id_last is null then
		dbms_output.put_line('В данном месяце поставок небыло.');
	end if;
end;

-- 7.4. Написать процедуру, которая выполняет копирование всех данных об указанном магазине, включая поставки. Аргумент процедуры - id_магазина. Для скопированной записи ставится отметка "копия" в поле название.

procedure P_Copy(store_id_ number)
as
	store_valid number(10);
	copy_store_id number(10);
	copy_supply_id number(10);

	cursor supplies_cursor is
	select *
	from supplies ss
	where ss.store_id = store_id_;
begin
	select count(*)
	into store_valid
	from stores s
	where s.store_id = store_id_;

	if store_valid = 0 then
		dbms_output.put_line('Введен некорректный ID_магазина.');
	end if;

	select max(s.store_id) + 1
	into copy_store_id
	from stores s;

	insert into stores (store_id, name, manager_full_name, address, phone)
	select copy_store_id, s.name || ' копия', s.manager_full_name, s.address, s.phone
	from stores s
	where s.store_id = store_id_;

	select max(supply_id)
	into copy_supply_id
	from supplies;

	for i in supplies_cursor loop
		copy_supply_id := copy_supply_id + 1;

		insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity)
		values (copy_supply_id, i.supplier_id, i.product_id, copy_store_id, i.supply_date, i.cost, i.quantity);
	end loop;
end;

end;
/
select store_id, PAC.F_SuppliersCount(store_id, to_date('2020', 'yyyy')) from stores;
select store_id, PAC.F_SuppliersCount(store_id) from stores;
select PAC.F_SuppliersCount(null, to_date('2020', 'yyyy')) from dual;

select supplier_id, PAC.F_AvgCost(supplier_id, to_date('2020', 'yyyy'), 'Электроника') from suppliers;
select supplier_id, PAC.F_AvgCost(supplier_id, to_date('2020', 'yyyy')) from suppliers;
select supplier_id, PAC.F_AvgCost(supplier_id, null, 'Электроника') from suppliers;
select supplier_id, PAC.F_AvgCost(supplier_id) from suppliers;
select PAC.F_AvgCost(null) from dual;

begin
	PAC.P_List('Монитор', to_date('2020-10', 'yyyy-mm'));
	PAC.P_List('Монитор', to_date('2021-12', 'yyyy-mm'));
	PAC.P_List('Монитор', null);
	PAC.P_List(null, to_date('2020-10', 'yyyy-mm'));
end;
/
savepoint A;

begin
	PAC.P_Copy(2);
	PAC.P_Copy(null);
end;
/
select * from stores where store_id in (2, 6);
select * from supplies where store_id in (2, 6);

rollback;

-- 8. Создать триггеры, включить обработчики исключений. Написать скрипты для проверки. При необходимости снять ограничения (если ограничение мешает проверить работу триггера).

-- 8.1. Написать триггер, активизирующийся при изменении содержимого таблицы "Поставки" и проверяющий, чтобы в один и тот же магазин от одного и того же поставщика было не более 10 поставок.

create or replace view supplies_view as
select * from supplies;

create or replace trigger T1
instead of
insert
on supplies_view
for each row
declare
	supplies_count number(10);
begin
	select count(*)
	into supplies_count
	from supplies ss
	where ss.supplier_id = :new.supplier_id
		and ss.store_id = :new.store_id;

	if supplies_count > 10 then
		raise_application_error(-20000, 'Превышено максимальное количество поставок.');
	end if;

	insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity)
	values (:new.supply_id, :new.supplier_id, :new.product_id, :new.store_id, :new.supply_date, :new.cost, :new.quantity);
end;
/
savepoint A;

insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (16, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (17, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (18, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (19, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (20, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (21, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (22, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (23, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (24, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (25, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);

select * from supplies;

rollback;

drop trigger T1;

-- 8.2. Написать триггер, сохраняющий статистику изменений таблицы "Поставки" в таблице "Поставки_Статистика", в которой хранится дата изменения, тип изменения (insert, update, delete).
-- Триггер также выводит на экран сообщение с указанием количества дней прошедших со дня последнего изменения.

create table supplies_statistics
(
	id number(10),
	change_date date,
	change_type varchar2(10),
	constraint pk_supplies_statistics primary key (id),
	constraint ch_supplies_statistics check (change_date is not null and change_type is not null)
);

create or replace trigger T2
after
insert or update or delete
on supplies
for each row
declare
	last_id number(10);
	last_change_date date;
	change_type varchar2(10);
begin
	select max(sst.id), max(sst.change_date)
	into last_id, last_change_date
	from supplies_statistics sst;

	if inserting then
		change_type := 'insert';
	elsif deleting then
		change_type := 'delete';
	else
		change_type := 'update';
	end if;

	if last_change_date is not null then
		dbms_output.put_line('Дней с момента последнего изменения: ' || trunc(sysdate - last_change_date) || '.');
	end if;

	insert into supplies_statistics (id, change_date, change_type)
	values (nvl(last_id + 1, 1), sysdate, change_type);
end;
/
savepoint A;

insert into supplies_statistics (id, change_date, change_type) values (1, to_date('2020-12-20', 'yyyy-mm-dd'), 'insert');

insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (16, 4, 8, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
update supplies ss set ss.cost = ss.cost * 1.2 where ss.supply_id = 16;
delete supplies ss where ss.supply_id = 16;

begin
	null;
end;
/
select * from supplies_statistics;

rollback;

drop trigger T2;

-- 8.3. Написать триггер, активизирующийся при вставке в таблицу "Поставки" и проверяющий наличие поставки в тот же магазин того же товара от того же поставщика.
-- Если такая поставка найдена, то вместо вставки количество суммируется, берётся максимальная сумма и самое позднее время поставки.

create or replace trigger T3
instead of
insert
on supplies_view
for each row
declare
	existing_supply_id number(10);
begin
	select min(ss.supply_id)
	into existing_supply_id
	from supplies ss
	where ss.store_id = :new.store_id
		and ss.product_id = :new.product_id
		and ss.supplier_id = :new.supplier_id;

	if existing_supply_id is null then
		insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity)
		values (:new.supply_id, :new.supplier_id, :new.product_id, :new.store_id, :new.supply_date, :new.cost, :new.quantity);
	else
		update supplies ss
		set ss.supply_date = greatest(ss.supply_date, :new.supply_date)
			, ss.cost = greatest(ss.cost, :new.cost)
			, ss.quantity = ss.quantity + :new.quantity
		where ss.supply_id = existing_supply_id;
	end if;
end;
/
savepoint A;

insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (16, 4, 1, 2, to_date('2020-10-23 06:05:55', 'yyyy-mm-dd hh24:mi:ss'), 1250000, 10);
insert into supplies_view (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (17, 4, 1, 2, to_date('2020-11-23 06:02:31', 'yyyy-mm-dd hh24:mi:ss'), 1375000, 11);

select * from supplies where supply_id in (16, 17);

rollback;

drop trigger T3;

-- Откат.

drop view supplies_view;

drop table supplies_statistics;

drop package PAC;

drop index index_products;
drop index index_suppliers;
