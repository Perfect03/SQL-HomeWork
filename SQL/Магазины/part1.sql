-- Вариант 5

-- 1. Написать команды создания таблиц заданной схемы с указанием необходимых ключей и ограничений. Все ограничения должны быть именованными (для первичных ключей имена должны начинаться с префикса "PK_", для вторичного ключа – "FK_", проверки - "CH_"). Ограничения: поля цена и количество не могут быть отрицательными; значение null допустимо только в поле адрес и телефон.

create table suppliers
(
	supplier_id number(10),
	name varchar2(100),
	address varchar2(100),
	phone varchar2(100),
	constraint pk_suppliers primary key (supplier_id),
	constraint ch_suppliers check (name is not null)
);

create table products
(
	product_id number(10),
	name varchar2(100),
	category varchar2(100),
	manufacturer varchar2(100),
	constraint pk_products primary key (product_id),
	constraint ch_products check (name is not null and category is not null and manufacturer is not null)
);

create table stores
(
	store_id number(10),
	name varchar2(100),
	manager_full_name varchar2(100),
	address varchar2(100),
	phone varchar2(100),
	constraint pk_stores primary key (store_id),
	constraint ch_stores check (name is not null and manager_full_name is not null)
);

create table supplies
(
	supply_id number(10),
	supplier_id number(10),
	product_id number(10),
	store_id number(10),
	supply_date date,
	cost number(10, 2),
	quantity number(10),
	constraint pk_supplies primary key (supply_id),
	constraint fk_supplies_suppliers foreign key (supplier_id) references suppliers (supplier_id),
	constraint fk_supplies_products foreign key (product_id) references products (product_id),
	constraint fk_supplies_stores foreign key (store_id) references stores (store_id),
	constraint ch_supplies check (supply_date is not null and cost is not null and quantity is not null and cost >= 0 and quantity >= 0)
);

-- 2. Заполнить созданные таблицы данными, 5 - 10 записей для каждой таблицы.

insert into suppliers (supplier_id, name, address, phone) values (1, 'ООО Интер', 'г. Томск, ул. Мокрушина, д. 1, кв. 120', '+7 404 555 32 85');
insert into suppliers (supplier_id, name, address, phone) values (2, 'AEY Inc.', 'Miami Beach, 975 Arthur Godfrey Rd #211', '+1 703 555 21 43');
insert into suppliers (supplier_id, name, address, phone) values (3, 'Манотек', 'г. Томск, пер. Нечевский, д. 21/1, помещение 1022', '+7 212 555 39 23');
insert into suppliers (supplier_id, name, address, phone) values (4, 'ООО Сибтеплоэлектрокомплект', 'г. Москва, ул. Бакунина, д. 26, ст. 1', '+7 773 555 76 93');
insert into suppliers (supplier_id, name, address, phone) values (5, 'Жирный кот', 'г. Томск, ул. ​Фёдора Лыткина, д. 14', '+7 617 555 32 95');

insert into products (product_id, name, category, manufacturer) values (1, 'Икра', 'Еда', 'OOO Фрутикра');
insert into products (product_id, name, category, manufacturer) values (2, 'Пицца', 'Еда', 'Жирный кот');
insert into products (product_id, name, category, manufacturer) values (3, 'Манометр', 'Приборы', 'OOO Манотек');
insert into products (product_id, name, category, manufacturer) values (4, 'Молоко', 'Еда', 'OOO Константа райх');
insert into products (product_id, name, category, manufacturer) values (5, 'Elcon черная', 'Эмали', 'ИП Рога и Копыта');
insert into products (product_id, name, category, manufacturer) values (6, 'ЦАПОН универсальный', 'Лаки', 'ИП Рога и Копыта');
insert into products (product_id, name, category, manufacturer) values (7, 'Аудиосистема', 'Электроника', 'ООО НПЦ Техноаналит');
insert into products (product_id, name, category, manufacturer) values (8, 'Монитор', 'Электроника', 'ООО Техно Стар');
insert into products (product_id, name, category, manufacturer) values (9, 'Мышь', 'Электроника', 'ООО Техно Стар');
insert into products (product_id, name, category, manufacturer) values (10, 'DECORIX матовая', 'Эмали', 'ООО Спутник');

insert into stores (store_id, name, manager_full_name, address, phone) values (1, 'Три кота', 'Юрий Станиславович Колесников', 'г. Томск, ул. Карла Маркса, д. 68, кв. 92', '+7 951 672 88 95');
insert into stores (store_id, name, manager_full_name, address, phone) values (2, 'Интант', 'Николай Кириллович Мельников', 'г. Томск, пер. Пионерский, д. 8, кв. 38', '+7 913 168 90 62');
insert into stores (store_id, name, manager_full_name, address, phone) values (3, 'e2e4', 'Анна Михайловна Никифорова', 'г. Томск, пер. Сухоозёрный, д. 15, кв. 39', '+7 913 681 37 61');
insert into stores (store_id, name, manager_full_name, address, phone) values (4, 'Лента', 'Михаил Тимофеевич Павлов', 'г. Томск, ул. Гагарина, д. 44, кв. 81', '+7 943 862 63 45');
insert into stores (store_id, name, manager_full_name, address, phone) values (5, 'ЭлкоПро', 'Иван Викторович Сорокин', 'г. Томск, тракт Чекистский, д. 51, кв. 80', '+7 923 838 91 57');

insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (1, 1, 1, 4, TO_DATE('2020-10-25 05:45:07', 'YYYY-MM-DD HH24:MI:SS'), 15000, 200);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (2, 5, 2, 4, TO_DATE('2020-10-29 19:09:19', 'YYYY-MM-DD HH24:MI:SS'), 20000, 30);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (3, 1, 4, 4, TO_DATE('2020-11-04 14:11:07', 'YYYY-MM-DD HH24:MI:SS'), 10000, 200);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (4, 3, 7, 3, TO_DATE('2020-11-02 11:24:25', 'YYYY-MM-DD HH24:MI:SS'), 1500000, 5);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (5, 3, 8, 3, TO_DATE('2020-10-20 19:21:31', 'YYYY-MM-DD HH24:MI:SS'), 1000000, 10);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (6, 3, 9, 3, TO_DATE('2020-10-27 17:35:18', 'YYYY-MM-DD HH24:MI:SS'), 125000, 25);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (7, 4, 8, 2, TO_DATE('2020-10-23 06:05:55', 'YYYY-MM-DD HH24:MI:SS'), 1250000, 10);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (8, 4, 9, 2, TO_DATE('2020-10-28 20:30:12', 'YYYY-MM-DD HH24:MI:SS'), 160000, 25);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (9, 4, 5, 5, TO_DATE('2020-10-26 21:12:33', 'YYYY-MM-DD HH24:MI:SS'), 15000, 100);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (10, 4, 6, 5, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 1000, 5000);

insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (11, 1, 4, 4, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 50, 1);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (12, 1, 4, 4, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 25, 1);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (13, 1, 4, 4, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 43, 1);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (14, 1, 4, 4, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 77, 1);
insert into supplies (supply_id, supplier_id, product_id, store_id, supply_date, cost, quantity) values (15, 1, 4, 4, TO_DATE('2020-11-06 15:33:10', 'YYYY-MM-DD HH24:MI:SS'), 58, 1);

-- 3. Написать запросы. Устранить дублирование только для тех случаев, где это потенциально возможно.

-- 3.1. Вывести товары из категорий "эмали" и "лаки" от производителя "ИП рога и копыта". Результат упорядочить по наименованию.

select *
from products
where lower(category) in ('эмали', 'лаки')
	and lower(manufacturer) = 'ип рога и копыта'
order by name;

-- 3.2. Сформировать список поставок за последнюю неделю. В выборке должны присутствовать только следующие поля: Название товара, дату поставки с точностью до дня, сумму поставки и название поставщика. Результат упорядочить по названию товара.

select distinct products.name
	, to_char(supply_date, 'YYYY-MM-DD') as "Date"
	, cost
	, suppliers.name
from supplies
	inner join suppliers on suppliers.supplier_id = supplies.supplier_id
	inner join products on products.product_id = supplies.product_id
where to_char(supply_date, 'YYYY-IW') = to_char(current_date, 'YYYY-IW')
order by products.name;

-- 3.3. Для каждого магазина сформировать годичную статистику суммарной стоимости поставок. В выборке должны присутствовать следующие поля: Название магазина, год, общая стоимость поставок, количество задействованных поставщиков.

select name
	, extract(year from supply_date) as year
	, sum(cost) as cost_sum
	, count(distinct supplier_id) as suppliers_count
from supplies
	inner join stores on stores.store_id = supplies.store_id
group by name, extract(year from supply_date);

-- 3.4. Для каждого поставщика найти общее число поставок, среднюю стоимость одной поставки, число магазинов, с которыми он работает, насколько самая дорогая поставка превышает среднюю стоимость (отличие считать в процентах). Исключить из выборки поставщиков работающих только с одним магазином.

select name
	, count(*) as supplies_count
	, avg(cost) as average_cost
	, count(distinct store_id) as stores_count
	, trunc(max(cost) * 100 / avg(cost)) - 100 as "Max to Average %"
from supplies
	inner join suppliers on suppliers.supplier_id = supplies.supplier_id
group by name
having count(distinct store_id) > 1;

-- 3.5. Найти все номера поставок молока, цена единицы товара в которых меньше средней.

with milk as
	(
		select supply_id
			, cost / quantity as price
		from supplies
			inner join products on products.product_id = supplies.product_id
		where lower(products.name) = 'молоко'
	)
	, avg as
	(
		select avg(price) as avg_price
		from milk
	)
select supply_id
from milk, avg
where price < avg_price;

-- 3.6. Выбрать поставщиков работающих с одним и менее магазинами.

with count as
	(
		select supplier_id
			, count(distinct store_id) as stores_count
		from supplies
		group by supplier_id
	)
select suppliers.*
from suppliers
	inner join count on count.supplier_id = suppliers.supplier_id
where stores_count <= 1;

-- 4. Написать запросы на изменение данных.
-- 4.1. Изменить названия тех магазинов, которые находятся в Томске, и в которые поставлялся товар от поставщика "ООО Интер". В название добавить слово "Интер". Например, "Космос" -> "Космос - Интер".

update stores
set name = name || ' - Интер'
where exists
(
	select 1
	from supplies
		inner join suppliers on suppliers.supplier_id = supplies.supplier_id
	where supplies.store_id = stores.store_id
		and lower(suppliers.name) = 'ооо интер'
		and lower(stores.address) like '%томск%'
);

-- 4.2. Удалить из базы товары, магазины и поставщиков не участвовавших в поставках.

delete from suppliers
where not exists
(
	select 1
	from supplies
	where supplies.supplier_id = suppliers.supplier_id
);

delete from products
where not exists
(
	select 1
	from supplies
	where supplies.product_id = products.product_id
);

delete from stores
where not exists
(
	select 1
	from supplies
	where supplies.store_id = stores.store_id
);

-- 5. Создать представления.

-- 5.1. Оформить запросы 4.1 - 4.2 в виде представления.

create view v_stores as
select distinct stores.store_id
	, stores.name
	|| case
		when lower(suppliers.name) = 'ооо интер'
			and lower(stores.address) like '%томск%'
		then ' - Интер'
	end as name
	, manager_full_name
	, stores.address
	, stores.phone
from supplies
	inner join suppliers on suppliers.supplier_id = supplies.supplier_id
	inner join stores on stores.store_id = supplies.store_id;

create view v_suppliers_active as
select distinct suppliers.*
from suppliers
	inner join supplies on supplies.supplier_id = suppliers.supplier_id;

create view v_products_active as
select distinct products.*
from products
	inner join supplies on supplies.product_id = products.product_id;
	
create view v_stores_active as
select distinct stores.*
from stores
	inner join supplies on supplies.store_id = stores.store_id;

-- 5.2. Создать представление со следующими полями: ID_магазина, название, ФИО директора, адрес, количество поставщиков, дата последней поставки.

create view v_stores_suppliers as
select stores.store_id
	, stores.name
	, manager_full_name
	, address
	, count(distinct supplier_id) as suppliers_count
	, max(supply_date) as latest_supply
from supplies
	inner join stores on stores.store_id = supplies.store_id
group by stores.store_id, stores.name, manager_full_name, address;

-- Откат.

drop table supplies;
drop table suppliers;
drop table products;
drop table stores;

drop view v_stores;
drop view v_suppliers_active;
drop view v_products_active;
drop view v_stores_active;
drop view v_stores_suppliers;
