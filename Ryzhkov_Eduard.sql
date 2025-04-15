/* 
 Контрольное задание №1
 Написать запрос, выводящий имя и фамилию самых бедных клиентов - среди замужных женщин, 
 не проживающих ни в Японии, ни в Бразилии, ни в Италии. 
 Богатство определяется по кредитному лимиту. [Отсортировать по CUST_LAST_NAME]. 
*/

SELECT CUST_FIRST_NAME, CUST_LAST_NAME
FROM CUSTOMERS 
WHERE COUNTRY NOT IN ('Japan', 'Brazil', 'Italy')
AND CUST_GENDER = 'F' 
AND CUST_MARITAL_STATUS = 'Married' 
AND CUST_CREDIT_LIMIT = (SELECT MIN(CUST_CREDIT_LIMIT) FROM CUSTOMERS)
ORDER BY CUST_LAST_NAME;



/*
 Контрольное задание №2
 Написать запрос, выводящий клиента с самым длинным домашним адресом, чей телефонный номер заканчивается на 77. 
 Вывести результат в одном столбце, в формате 
 “Name: [cust_first_name] [cust_last_name]; city: [cust_city]; address: [cust_street_address]; number:[cust_main_phone_number]; 
 email: [cust_email]; ”. (всё, что обернуто в [] – названия полей (столбцов) таблицы). 
 */

SELECT 'Name: ' || c.CUST_FIRST_NAME || ' ' || c.CUST_LAST_NAME || '; ' || 
       'City: ' || c.CUST_CITY || '; ' ||
       'Address: ' || c.CUST_STREET_ADDRESS || '; ' ||  
       'Number: ' || c.CUST_MAIN_PHONE_NUMBER || '; ' ||
       'Email: ' || c.CUST_EMAIL AS CLIENT_WITH_LONGEST_ADDRESS
FROM CUSTOMERS c
WHERE c.CUST_MAIN_PHONE_NUMBER LIKE '%77'
ORDER BY LENGTH(c.CUST_STREET_ADDRESS) DESC
FETCH FIRST 1 ROWS ONLY;


/*
 Контрольное задание №3
 Написать запрос, выводящий всех клиентов, которые купили самый дешевый продукт 
 (цена считается от цены продажи - cust_list_price) в субкатегории 'Sweaters - Men' или 'Sweaters - Women' 
 (связка таблиц CUSTOMERS -> SALES -> PRODUCTS), среди тех, кто родился позже 1980 года, вывод должен быть отсортирован по cust_id. 
 */

SELECT c.*
FROM CUSTOMERS c
JOIN SALES s ON c.CUST_ID = s.CUST_ID
JOIN PRODUCTS p ON s.PROD_ID = p.PROD_ID
WHERE p.PROD_SUBCATEGORY IN ('Sweaters - Men', 'Sweaters - Women')
AND c.CUST_YEAR_OF_BIRTH > 1980
AND p.PROD_LIST_PRICE = (SELECT MIN(p2.PROD_LIST_PRICE) 
	FROM PRODUCTS p2
	JOIN SALES s2 ON p2.PROD_ID = s2.PROD_ID
	WHERE p2.PROD_SUBCATEGORY IN ('Sweaters - Men', 'Sweaters - Women'))
ORDER BY c.CUST_ID;


/*
 Контрольное задание №4
 Написать запрос, выводящий всех клиентов-мужчин с уровнем дохода "D", 
 у которых не заполнено поле "семейное положение" и которые проживают в США или Германии (с использованием EXISTS). Отсортировать по cust_id. 
 */

SELECT * 
FROM CUSTOMERS c 
WHERE EXISTS 
(SELECT * FROM CUSTOMERS c2
WHERE c.CUST_MARITAL_STATUS IS NULL)
AND c.CUST_GENDER = 'M'
AND c.CUST_INCOME_LEVEL LIKE 'D%'
AND c.COUNTRY IN ('United States of America', 'Germany')
ORDER BY c.CUST_ID;


/*
 Контрольное задание №5
 Написать запрос, выводящий среднюю сумму покупки (сумма покупки является произведением цены товара (prod_list_price) 
 на количество проданного товара (quantity_sold)) в каждой стране, полное название страны. Отсортировать в порядке убывания средней суммы. 
 */

SELECT ROUND(AVG(p.PROD_LIST_PRICE * s.QUANTITY_SOLD), 2) AS AVG_PRICE, c.COUNTRY -- округлил до двух знаков после запятой для удобства
FROM SALES s
JOIN PRODUCTS p ON s.PROD_ID = p.PROD_ID
JOIN CUSTOMERS c ON s.CUST_ID = c.CUST_ID
GROUP BY c.COUNTRY
ORDER BY AVG_PRICE DESC;


/*
Контрольное задание №6
Написать запрос, выводящий "популярность" почтовых доменов клиентов, т.е. количество клиентов с почтой в каждом из доменов. 
*/

SELECT SUBSTR(CUST_EMAIL, INSTR(CUST_EMAIL, '@') + 1) AS EMAIL_DOMEN, COUNT(*) AS EMAIL_COUNT
FROM CUSTOMERS c
GROUP BY SUBSTR(CUST_EMAIL, INSTR(CUST_EMAIL, '@') + 1)
ORDER BY EMAIL_COUNT DESC;

--SELECT DISTINCT CUST_EMAIL FROM CUSTOMERS


/*
 Контрольное задание №7
 Написать запрос, выводящий распределение суммы проданных товаров в единицах (quantity_sold) категории "Men" по странам 
 (т.е. распределение по странам, в которых проживают клиенты), в конечной выборке оставить те страны, 
 в которых общее количество проданных товаров в единицах выше, чем средняя сумма проданных товаров в единицах этой категории в стране (по всему миру). 
 Упорядочить по полному названию стран. 
 */

SELECT c.COUNTRY, SUM(s.QUANTITY_SOLD) AS TOTAL_SOLD
FROM SALES s
JOIN CUSTOMERS c ON s.CUST_ID = c.CUST_ID
JOIN PRODUCTS p ON s.PROD_ID = p.PROD_ID
WHERE p.PROD_CATEGORY = 'Men'
GROUP BY c.COUNTRY
HAVING SUM(s.QUANTITY_SOLD) > (SELECT AVG(COUNTRY_TOTAL)
FROM (SELECT SUM(s2.QUANTITY_SOLD) AS COUNTRY_TOTAL
	FROM SALES s2
	JOIN CUSTOMERS c2 ON s2.CUST_ID = c2.CUST_ID
	JOIN PRODUCTS p2 ON s2.PROD_ID = p2.PROD_ID
	WHERE p2.PROD_CATEGORY = 'Men'
	GROUP BY c2.COUNTRY))
ORDER BY c.COUNTRY;


/*
 Контрольное задание №8
 Написать запрос, выводящий процентное соотношение мужчин и женщин, проживающих в каждой стране, 
 отсортированное по названию страны в алфавитном порядке. Столбцы в выводе должны быть такими: 
 «Страна», «% мужчин», «% женщин» [использовать WITH]. Упорядочить по полному названию стран. 
*/

WITH GENDER_PERCENT AS (
	SELECT c.COUNTRY, 
	SUM(CASE WHEN c.CUST_GENDER = 'M' THEN 1 ELSE 0 END) AS MALE_COUNTER,
	SUM(CASE WHEN c.CUST_GENDER = 'F' THEN 1 ELSE 0 END) AS FEMALE_COUNTER,
	COUNT(*) AS TOTAL_COUNTER
FROM CUSTOMERS c
GROUP BY c.COUNTRY)
SELECT COUNTRY AS "Страна", 
	ROUND(MALE_COUNTER * 100 / TOTAL_COUNTER, 1) AS "% мужчин", 	-- округлил до 1 знака после запятой
	ROUND(FEMALE_COUNTER * 100 / TOTAL_COUNTER, 1) AS "% женщин"
FROM GENDER_PERCENT
ORDER BY COUNTRY;


/*
 Контрольное задание №9
 Написать запрос, выводящий максимальное суммарное количество проданных единиц товара (quantity_sold) за день для каждого продукта 
 (т.е. продукты в выводе не должны повторяться). Запрос должен выводить TOP 20 строк, отсортированных по убыванию количества проданных единиц товара 
 (Столбцы должны быть такими: "Макс покуп/день", prod_name) 
 [Под первым столбцом подразумевается объединение в одно поле количества покупок и последней даты, за которую сделаны эти покупки]. 
 */

WITH MAX_DAY AS (
	SELECT SUM(s.QUANTITY_SOLD) AS TOTAL_QUANTITY_SOLD, s.TIME_ID, p.PROD_NAME
FROM SALES s
JOIN PRODUCTS p ON s.PROD_ID = p.PROD_ID
GROUP BY p.PROD_NAME, s.TIME_ID), 
MAX_SALES AS (
	SELECT PROD_NAME, MAX(TOTAL_QUANTITY_SOLD) AS MAX_SOLD
FROM MAX_DAY
GROUP BY PROD_NAME)
SELECT TO_CHAR(md.TOTAL_QUANTITY_SOLD) || ' ед./' || TO_CHAR(md.TIME_ID, 'YYYY-MM-DD') AS "Макс покуп/день", md.PROD_NAME
FROM MAX_DAY md
JOIN MAX_SALES ms ON md.PROD_NAME = ms.PROD_NAME AND md.TOTAL_QUANTITY_SOLD = ms.MAX_SOLD
ORDER BY md.TOTAL_QUANTITY_SOLD DESC
FETCH FIRST 20 ROWS ONLY;


/*
 Контрольное задание №10
 Написать запрос, выводящий максимальное суммарное количество проданных единиц товара за день для каждой категории продуктов. 
 Отсортировать по убыванию количества. (Столбцы должны быть такими: "Макс за день", prod_category). [Под первым столбцом подразумевается одно число]. 
 */

SELECT MAX(DAY_SUM) AS "Макс за день", PROD_CATEGORY
FROM (
	SELECT s.TIME_ID, p.PROD_CATEGORY, SUM(s.QUANTITY_SOLD) AS DAY_SUM
	FROM SALES s
	JOIN PRODUCTS p ON s.PROD_ID = p.PROD_ID
	GROUP BY s.TIME_ID, p.PROD_CATEGORY)
GROUP BY PROD_CATEGORY
ORDER BY "Макс за день" DESC;



/*
 Контрольное задание №11
 Написать запрос, который создаст таблицу с именем sales_[имя пользователя в ОС]_[Ваше имя]_[Ваша фамилия], 
 содержащую строки из таблицы sh.sales за один пиковый месяц. (Т.е. месяц, за который получена максимальная выручка). 
 Показать все поля таблицы в порядке возрастания дат.  
 */

CREATE TABLE SALES_BIGSURMOON_RYZHKOV_EDUARD AS SELECT *
FROM SALES
WHERE TRUNC(TIME_ID, 'MM') = (
	SELECT TRUNC(TIME_ID, 'MM')
	FROM SALES
	GROUP BY TRUNC(TIME_ID, 'MM')
	ORDER BY SUM(amount_sold) DESC
	FETCH FIRST 1 ROW ONLY)
ORDER BY TIME_ID;

SELECT * FROM SALES_BIGSURMOON_RYZHKOV_EDUARD ORDER BY TIME_ID ASC;


/*
 Контрольное задание №12
 Написать запрос, который для созданной в задании 11 таблицы изменит значение поля time_id на формат 'DD.MM.YYYY HH24:MI:SS' (см. NLS_DATE_FORMAT). 
 Значение hh24:mm:ss должно выбираться случайным образом. Сохранить сделанные изменения. Показать все поля таблицы в порядке возрастания дат.
 SELECT dbms_random.value FROM DUAL возвращает случайное значение от 0 до 1;  
 */

UPDATE SALES_BIGSURMOON_RYZHKOV_EDUARD
SET TIME_ID = TRUNC(TIME_ID) + DBMS_RANDOM.VALUE(0, 1);



SELECT PROD_ID, CUST_ID, TO_CHAR(TRUNC(TIME_ID) 
	+ (TRUNC(DBMS_RANDOM.VALUE(0, 24)) / 24)
	+ (TRUNC(DBMS_RANDOM.VALUE(0, 60)) / 1440)
	+ (TRUNC(DBMS_RANDOM.VALUE(0, 60)) / 86400), 'DD.MM.YYYY HH24:MI:SS') AS TIME_ID,
CHANNEL_ID, PROMO_ID, QUANTITY_SOLD, AMOUNT_SOLD
FROM SALES_BIGSURMOON_RYZHKOV_EDUARD
ORDER BY TIME_ID;


/*
 Контрольное задание №13
 Написать запрос, выводящий почасовую разбивку количества операций продажи для Вашей таблицы.  
 */

SELECT TO_CHAR(TIME_ID, 'HH24') AS HOURS, COUNT(*) AS SALES_COUNTER
FROM SALES_BIGSURMOON_RYZHKOV_EDUARD
GROUP BY TO_CHAR(TIME_ID, 'HH24')
ORDER BY HOURS;


/*
 Контрольное задание №14
 Написать запрос, который удалит созданную в задании 11 таблицу. Сохранить сделанные изменения.
 */

DROP TABLE SALES_BIGSURMOON_RYZHKOV_EDUARD;

COMMIT;

SELECT * FROM SALES_BIGSURMOON_RYZHKOV_EDUARD;