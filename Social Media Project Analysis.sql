USE ig_clone;

show tables;

select count(*) from Users;
select count(*) from follows;
select count(*) from Photos;
select count(*) from Likes;
select count(*) from Comments;
select count(*) from Photos;
select count(*) from tags;
select count(*) from Photo_tags;






-- Question 2 --
# Combined User Activity Profile
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS posts,
    COUNT(DISTINCT l.photo_id) AS likes,
    COUNT(DISTINCT c.id) AS comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY posts desc, likes desc, comments DESC;





-- Question 3 --
SELECT 
    ROUND(AVG(tag_count), 2) AS avg_tags_per_post
FROM (
    SELECT 
        p.id AS photo_id,
        COUNT(pt.tag_id) AS tag_count
    FROM photos p
    LEFT JOIN photo_tags pt
        ON p.id = pt.photo_id
    GROUP BY p.id
) t;


-- Question 4 --
WITH user_engagement AS (
    SELECT 
        p.user_id,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT 
    u.id,
    u.username,
    ue.total_likes,
    ue.total_comments,
    (ue.total_likes + ue.total_comments) AS engagement_score,
    RANK() OVER (
        ORDER BY (ue.total_likes + ue.total_comments) DESC
    ) AS engagement_rank
FROM user_engagement ue
JOIN users u 
    ON ue.user_id = u.id
ORDER BY engagement_rank;

-- Question 5 --

-- Highest by Followers -- 
with Highest_Followers as(SELECT 
    u.username,
    COUNT(f.follower_id) AS followers,
    rank() over(order by COUNT(f.follower_id) desc) as rnk
FROM users u
LEFT JOIN follows f ON u.id = f.followee_id
GROUP BY  u.username
)
select username ,followers
from Highest_Followers where rnk = 1 ;


-- Highest by Following -- 
with Highest_following as (SELECT 
    u.username,
    COUNT(f.followee_id) AS following,
    rank() Over(Order by COUNT(f.followee_id) desc ) as rnk 
    FROM users u
LEFT JOIN follows f ON u.id = f.follower_id
GROUP BY u.id, u.username
)

Select username ,
following
from Highest_following 
where rnk = 1;



-- Question 6 --

WITH user_post_stats AS (
    SELECT 
        p.user_id,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT 
    u.id,
    u.username,
    ups.total_posts,
    ups.total_likes,
    ups.total_comments,
    ROUND(
        (ups.total_likes + ups.total_comments) / ups.total_posts, 
        2
    ) AS avg_engagement_per_post
FROM user_post_stats ups
JOIN users u 
    ON ups.user_id = u.id
ORDER BY avg_engagement_per_post DESC;


-- Question 7 --

SELECT 
    u.id,
    u.username
FROM users u
LEFT JOIN likes l 
    ON u.id = l.user_id
WHERE l.user_id IS NULL;




-- Question 10 --
WITH user_photos AS (
    SELECT 
        id AS photo_id,
        user_id
    FROM photos
),
likes_per_user AS (
    SELECT 
        up.user_id,
        COUNT(l.user_id) AS total_likes
    FROM user_photos up
    LEFT JOIN likes l 
        ON up.photo_id = l.photo_id
    GROUP BY up.user_id
),
comments_per_user AS (
    SELECT 
        up.user_id,
        COUNT(c.id) AS total_comments
    FROM user_photos up
    LEFT JOIN comments c 
        ON up.photo_id = c.photo_id
    GROUP BY up.user_id
),
tags_per_user AS (
    SELECT 
        up.user_id,
        COUNT(pt.tag_id) AS total_tags
    FROM user_photos up
    LEFT JOIN photo_tags pt 
        ON up.photo_id = pt.photo_id
    GROUP BY up.user_id
)
SELECT 
    u.id,
    u.username,
    COALESCE(lu.total_likes, 0) AS total_likes,
    COALESCE(cu.total_comments, 0) AS total_comments,
    COALESCE(tu.total_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN likes_per_user lu ON u.id = lu.user_id
LEFT JOIN comments_per_user cu ON u.id = cu.user_id
LEFT JOIN tags_per_user tu ON u.id = tu.user_id
ORDER BY total_likes DESC ,total_comments DESC, total_photo_tags DESC;


-- Question 11 --
WITH monthly_likes AS (
    SELECT 
        p.user_id,
        DATE_FORMAT(l.created_at, '%Y-%m') AS `year_month`,
        COUNT(*) AS likes_count
    FROM photos p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY 
        p.user_id,
        DATE_FORMAT(l.created_at, '%Y-%m')
),
monthly_comments AS (
    SELECT 
        p.user_id,
        DATE_FORMAT(c.created_at, '%Y-%m') AS `year_month`,
        COUNT(*) AS comments_count
    FROM photos p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY 
        p.user_id,
        DATE_FORMAT(c.created_at, '%Y-%m')
),
monthly_engagement AS (
    SELECT 
        COALESCE(ml.user_id, mc.user_id) AS user_id,
        COALESCE(ml.`year_month`, mc.`year_month`) AS `year_month`,
        COALESCE(ml.likes_count, 0) AS likes,
        COALESCE(mc.comments_count, 0) AS comments
    FROM monthly_likes ml
    LEFT JOIN monthly_comments mc
        ON ml.user_id = mc.user_id
       AND ml.`year_month` = mc.`year_month`
)
SELECT 
    u.id,
    u.username,
    me.`year_month`,
    me.likes,
    me.comments,
    (me.likes + me.comments) AS total_engagement,
    RANK() OVER (
        PARTITION BY me.`year_month`
        ORDER BY (me.likes + me.comments) DESC
    ) AS engagement_rank
FROM monthly_engagement me
JOIN users u 
    ON me.user_id = u.id
ORDER BY me.`year_month`, engagement_rank;



-- Question 12 --
WITH hashtag_likes AS (
    SELECT
        t.id AS tag_id,
        t.tag_name,
        COUNT(l.user_id) AS total_likes,
        COUNT(DISTINCT p.id) AS total_posts
    FROM tags t
    JOIN photo_tags pt 
        ON t.id = pt.tag_id
    JOIN photos p 
        ON pt.photo_id = p.id
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY t.id, t.tag_name
),
hashtag_avg_likes AS (
    SELECT
        tag_name,
        ROUND(total_likes / total_posts, 2) AS avg_likes_per_post
    FROM hashtag_likes
)
SELECT
    tag_name,
    avg_likes_per_post
FROM hashtag_avg_likes
ORDER BY avg_likes_per_post DESC;


-- Question 13 --
SELECT 
    u1.id AS user_id,
    u1.username AS user_name,
    u2.id AS followed_by_user_id,
    u2.username AS followed_by_user_name,
    f2.created_at AS followed_back_at
FROM follows f1
JOIN follows f2
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
   AND f2.created_at > f1.created_at
JOIN users u1
    ON f2.follower_id = u1.id
JOIN users u2
    ON f2.followee_id = u2.id;


-- SUBJECTIVE QUESTIONS --

-- Question 1 --


-- (Users whose posts receive the most likes + comments) -- 
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT l.user_id) AS total_likes_received,
    COUNT(DISTINCT c.id) AS total_comments_received,
    COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS total_engagement
FROM users u
JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY total_engagement DESC;



-- Consistently Active Users -- 
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT l.photo_id) AS likes_given,
    COUNT(DISTINCT c.id) AS comments_made,
    COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) AS total_interactions
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY total_interactions DESC;


-- (Users who both post and engage) -- 
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS posts,
    COUNT(DISTINCT l.photo_id) AS likes_given,
    COUNT(DISTINCT c.id) AS comments_made
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
HAVING posts > 0 
   AND (likes_given + comments_made) > 0
ORDER BY posts DESC, (likes_given + comments_made) DESC;


-- Question 2 --

-- Identify Completely Inactive Users -- 
SELECT 
    u.id,
    u.username
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
WHERE p.id IS NULL
  AND l.user_id IS NULL
  AND c.user_id IS NULL;


-- Users Who Have Never Posted (But Engage Passively) -- 
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT l.photo_id) AS likes_given,
    COUNT(DISTINCT c.id) AS comments_made
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
WHERE p.id IS NULL
GROUP BY u.id, u.username
HAVING likes_given > 0 OR comments_made > 0;


-- Users Who Posted But Never Got Engagement --
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS total_posts
FROM users u
JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
HAVING COUNT(l.user_id) = 0
   AND COUNT(c.id) = 0;


-- Recommend Trending Hashtags to Inactive Users --
SELECT 
    t.tag_name,
    COUNT(*) AS usage_count
FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY usage_count DESC
LIMIT 5;

-- Re-Engagement Target List (High Priority) -- 
SELECT 
    u.id,
    u.username
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
HAVING COUNT(p.id) = 0
   AND COUNT(l.user_id) = 0
   AND COUNT(c.id) = 0;



-- Question 3 -- 

-- High-Engagement Hashtags -- 
WITH hashtag_engagement AS (
    SELECT
        t.tag_name,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    JOIN photos p ON pt.photo_id = p.id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY t.tag_name
)
SELECT
    tag_name,
    total_posts,
    ROUND((total_likes + total_comments) / total_posts, 2) AS avg_engagement_per_post
FROM hashtag_engagement
ORDER BY avg_engagement_per_post DESC;



-- Question 4 -- 


-- Engagement by Hour of Posting -- 
SELECT 
    HOUR(p.created_dat) AS post_hour,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.user_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    ROUND(
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) 
        / COUNT(DISTINCT p.id), 
        2
    ) AS avg_engagement_per_post
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY post_hour
ORDER BY avg_engagement_per_post DESC;


-- Engagement by Day of Week --
SELECT 
    DAYNAME(p.created_dat) AS post_day,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.user_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    ROUND(
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) 
        / COUNT(DISTINCT p.id), 
        2
    ) AS avg_engagement_per_post
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY post_day
ORDER BY avg_engagement_per_post DESC;





-- Question 5 --

-- Users with Highest Followers -- 
SELECT 
    u.id,
    u.username,
    COUNT(f.follower_id) AS followers
FROM users u
LEFT JOIN follows f ON u.id = f.followee_id
GROUP BY u.id, u.username
ORDER BY followers DESC;

-- Engagement Rate per User (Likes + Comments per Post) -- 
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS posts,
    COUNT(DISTINCT l.user_id) AS likes_received,
    COUNT(DISTINCT c.id) AS comments_received,
    ROUND(
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) 
        / COUNT(DISTINCT p.id),
        2
    ) AS avg_engagement_per_post
FROM users u
JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
HAVING posts > 0
ORDER BY avg_engagement_per_post DESC;


-- Influencer Candidate Selection --
WITH follower_counts AS (
    SELECT 
        followee_id AS user_id,
        COUNT(*) AS followers
    FROM follows
    GROUP BY followee_id
),

post_counts AS (
    SELECT 
        user_id,
        COUNT(*) AS posts
    FROM photos
    GROUP BY user_id
),

engagement_received AS (
    SELECT 
        p.user_id,
        COUNT(DISTINCT l.user_id) AS likes_received,
        COUNT(DISTINCT c.id) AS comments_received
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)

SELECT
    u.id,
    u.username,
    fc.followers,
    pc.posts,
    er.likes_received,
    er.comments_received,
    ROUND(
        (er.likes_received + er.comments_received) / pc.posts,
        2
    ) AS avg_engagement_per_post
FROM users u
JOIN follower_counts fc ON u.id = fc.user_id
JOIN post_counts pc ON u.id = pc.user_id
JOIN engagement_received er ON u.id = er.user_id
WHERE pc.posts >= 5
ORDER BY avg_engagement_per_post DESC, fc.followers DESC;







-- Question 6 --

-- Power Creators (High Content + High Engagement)
WITH posts AS (
  SELECT user_id, COUNT(*) posts FROM photos GROUP BY user_id
),
eng AS (
  SELECT p.user_id,
         COUNT(DISTINCT l.user_id) likes_rec,
         COUNT(DISTINCT c.id) comments_rec
  FROM photos p
  LEFT JOIN likes l ON p.id=l.photo_id
  LEFT JOIN comments c ON p.id=c.photo_id
  GROUP BY p.user_id
)
SELECT u.id, u.username, posts, (likes_rec+comments_rec) AS engagement
FROM users u
JOIN posts p ON u.id=p.user_id
JOIN eng e ON u.id=e.user_id
WHERE posts>=5
ORDER BY engagement DESC;



-- Influencer / High-Impact Users (Followers + Engagement Efficiency) -- 
WITH followers AS (
  SELECT followee_id user_id, COUNT(*) followers FROM follows GROUP BY followee_id
),
posts AS (
  SELECT user_id, COUNT(*) posts FROM photos GROUP BY user_id
),
eng AS (
  SELECT p.user_id,
         COUNT(DISTINCT l.user_id)+COUNT(DISTINCT c.id) eng
  FROM photos p
  LEFT JOIN likes l ON p.id=l.photo_id
  LEFT JOIN comments c ON p.id=c.photo_id
  GROUP BY p.user_id
)
SELECT u.id,u.username,f.followers, p.posts, ROUND(eng/p.posts,2) avg_eng
FROM users u
JOIN followers f ON u.id=f.user_id
JOIN posts p ON u.id=p.user_id
JOIN eng e ON u.id=e.user_id
WHERE p.posts>=5
ORDER BY avg_eng DESC;




-- Active Engagers (Non-Creators) --
SELECT u.id,u.username,
       COUNT(DISTINCT l.photo_id) likes_given,
       COUNT(DISTINCT c.id) comments_made
FROM users u
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN likes l ON u.id=l.user_id
LEFT JOIN comments c ON u.id=c.user_id
WHERE p.id IS NULL
GROUP BY u.id,u.username
HAVING likes_given>0 OR comments_made>0;








-- Content-Interest Segments (Hashtag Affinity) -- 
SELECT u.id,u.username,t.tag_name,COUNT(*) interactions
FROM users u
JOIN likes l ON u.id=l.user_id
JOIN photo_tags pt ON l.photo_id=pt.photo_id
JOIN tags t ON pt.tag_id=t.id
GROUP BY u.id,u.username,t.tag_name
ORDER BY interactions DESC;





-- Question 7 -- 


-- ANSWER IN FILE -- 





-- Question 8 -- 



-- Most Loyal / Valuable Users (Based on Engagement & Activity) -- 
WITH user_engagement AS (
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments,
        ROUND(
            (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) 
            / NULLIF(COUNT(DISTINCT p.id), 0),
            2
        ) AS avg_engagement_per_post
    FROM users u
    JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY u.id, u.username
)
SELECT *
FROM user_engagement
ORDER BY avg_engagement_per_post DESC, total_posts DESC
LIMIT 20;


-- Re-Engaging Inactive Users -- 
SELECT u.id, u.username
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
WHERE p.id IS NULL
  AND l.user_id IS NULL
  AND c.id IS NULL;




-- Influencer Marketing Candidates --
WITH base AS (
    SELECT
        u.id,
        u.username,
        COUNT(DISTINCT f.follower_id) AS followers,
        COUNT(DISTINCT p.id) AS posts
    FROM users u
    JOIN photos p ON u.id = p.user_id
    LEFT JOIN follows f ON u.id = f.followee_id
    GROUP BY u.id, u.username
),
engagement AS (
    SELECT
        p.user_id,
        COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    b.id,
    b.username,
    b.followers,
    b.posts,
    ROUND(e.total_engagement / b.posts, 2) AS avg_engagement
FROM base b
JOIN engagement e ON b.id = e.user_id
ORDER BY followers DESC, avg_engagement DESC
LIMIT 20;




-- Identifying Brand Ambassadors -- 
SELECT
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS posts,
    COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS engagement
FROM users u
JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
HAVING engagement > 200
ORDER BY engagement DESC;