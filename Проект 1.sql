--Задание 1
--Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки»

SELECT COUNT(p.post_type_id)
FROM stackoverflow.posts AS p 
JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id 
WHERE pt.type = 'Question' AND (p.score > 300 OR p.favorites_count >= 100)

--Задание 2
--Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

SELECT ROUND(AVG(daycount))
FROM 
(SELECT COUNT(p.post_type_id) AS daycount
FROM stackoverflow.posts AS p 
JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id 
WHERE pt.type = 'Question' AND p.creation_date::date BETWEEN '01-11-2008' AND '18-11-2008'
GROUP BY p.creation_date::date) AS questions 

--Задание 3
--Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users AS u 
JOIN stackoverflow.badges AS b ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date 

--Задание 4
--Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT v.post_id) AS voted_posts
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id = p.user_id
JOIN stackoverflow.votes AS v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn';

--Задание 5
--Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.

SELECT *, RANK() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY rank DESC 

--Задание 6
--Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
--Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
--Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT u.id, COUNT(v.id)
FROM stackoverflow.users AS u 
JOIN stackoverflow.votes AS v ON u.id = v.user_id
JOIN stackoverflow.vote_types AS vt ON v.vote_type_id = vt.id 
WHERE vt.name = 'Close'
GROUP BY u.id
ORDER BY COUNT(v.id) DESC, u.id DESC
LIMIT 10

--Задание 7
--Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
--Отобразите несколько полей:
--идентификатор пользователя;
--число значков;
--место в рейтинге — чем больше значков, тем выше рейтинг.
--Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
--Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT DISTINCT b.user_id AS uid, 
    COUNT(*) AS badges_count,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
FROM stackoverflow.badges AS b
WHERE b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY badges_count DESC, user_id ASC
LIMIT 10

--Задание 8
/*Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT title, user_id, score, ROUND(AVG(score) OVER(PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score != 0

--Задание 9
--Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
--Посты без заголовков не должны попасть в список.

SELECT title 
FROM
(SELECT p.title AS title, COUNT(b.id) AS badges
    FROM stackoverflow.badges AS b
    JOIN stackoverflow.users AS u ON b.user_id = u.id
    JOIN stackoverflow.posts AS p ON u.id = p.user_id
    WHERE title IS NOT NULL
    GROUP BY title
HAVING COUNT(b.id) > 1000
) AS bc 
WHERE title IS NOT NULL 

--Задание 10
/*Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу. */

SELECT id, views,
    CASE
        WHEN views >= 350 THEN 1
        WHEN views < 350 AND views >= 100 THEN 2
        WHEN views < 100 THEN 3
    END
FROM stackoverflow.users
WHERE views > 0 AND location LIKE '%Canada%'

--Задание 11
/*Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

with grou AS (SELECT id, views,
    CASE
        WHEN views >= 350 THEN 1
        WHEN views < 350 AND views >= 100 THEN 2
        WHEN views < 100 THEN 3
    END as grop 
FROM stackoverflow.users
WHERE views > 0 AND location LIKE '%Canada%'),
lie AS (SELECT *, MAX(views) OVER (PARTITION BY grop) AS maxvi
FROM grou
GROUP BY id, views, grop 
ORDER BY MAX(views) DESC, id ASC)
SELECT id, grop, views
FROM lie
WHERE views = maxvi 

--Задание 12
/* Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. 
Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением. */

WITH t1 AS (SELECT EXTRACT(day from creation_date::date) AS da, COUNT(id) OVER (ORDER BY EXTRACT(day from creation_date::date)) AS daycount
FROM stackoverflow.users
WHERE creation_date BETWEEN '2008-11-01' AND '2008-12-01'),
t2 AS (SELECT *, COUNT(*)
FROM t1
GROUP BY da, daycount)
SELECT *
FROM t2 
ORDER BY da

--Задание 13
/* Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом. */

SELECT user_id,
       post_date - reg_date AS time_int
FROM (SELECT p.user_id,
       u.creation_date AS reg_date,
       p.creation_date AS post_date,
       ROW_NUMBER() OVER(PARTITION BY p.user_id ORDER BY p.creation_date) AS post_rank
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON p.user_id=u.id) AS tb
WHERE post_rank = 1;