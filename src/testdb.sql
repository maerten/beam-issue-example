

-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS posts_id_seq;

-- Table Definition
CREATE TABLE "public"."posts" (
    "id" int4 NOT NULL DEFAULT nextval('posts_id_seq'::regclass),
    "username" varchar,
    PRIMARY KEY ("id")
);

-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS users_id_seq;

-- Table Definition
CREATE TABLE "public"."users" (
    "id" int4 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
    "name" varchar,
    "email" varchar,
    PRIMARY KEY ("id")
);

INSERT INTO "public"."posts" ("id", "username") VALUES
(1, 'user1'),
(2, 'user1'),
(3, 'user2'),
(4, 'user3'),
(5, 'user1');

INSERT INTO "public"."users" ("id", "name", "email") VALUES
(1, 'user1', 'user1@email.com'),
(2, 'user2', 'user2@email.com');

