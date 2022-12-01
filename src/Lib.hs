{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}
module Lib
    ( testQuery
    ) where

import Database.Beam
import Database.Beam.Postgres
import Database.Beam.Migrate.Simple
import Database.Beam.Migrate.Generics
import Database.Beam.Migrate.Backend
import qualified Database.Beam.Backend.SQL.BeamExtensions as BeamExtensions

import Database.Beam.Migrate.Generics ( HasDefaultSqlDataType(..))
import Database.Beam.Migrate.SQL ( BeamMigrateSqlBackend(..))
import Database.Beam.Backend.SQL
import Database.PostgreSQL.Simple

import GHC.Int
import qualified Data.Text as T


import qualified Database.Beam.Postgres.Full as Pg


--
-- user
--
data UserT f = User {
  userId :: Columnar f (BeamExtensions.SqlSerial Int64),
  userName :: Columnar f (T.Text),
  userEmail :: Columnar f (T.Text)
} deriving (Generic, Beamable)

type User = UserT Identity
type UserKey = PrimaryKey UserT Identity
instance Show User

instance (Beamable UserT, Typeable UserT) => Table (UserT) where
  data PrimaryKey (UserT) f = UserKey (Columnar f (BeamExtensions.SqlSerial Int64)) deriving (Generic, Beamable)
  primaryKey = UserKey . userId

--
-- post
--
data PostT f = Post {
  postId :: Columnar f (BeamExtensions.SqlSerial Int64),
  postUsername :: Columnar f (T.Text)
} deriving (Generic, Beamable)


type Post = PostT Identity
type PostKey = PrimaryKey PostT Identity
instance Show Post

instance (Beamable PostT, Typeable PostT) => Table (PostT) where
  data PrimaryKey (PostT) f = PostKey (Columnar f (BeamExtensions.SqlSerial Int64)) deriving (Generic, Beamable)
  primaryKey = PostKey . postId




--
-- database schema
--
data MyDb f = MyDb {
                        dbUsers :: f (TableEntity (UserT)),
                        dbPosts :: f (TableEntity (PostT))
                      }
                      deriving stock (Generic)
                      deriving anyclass (Database Postgres)

myCheckedDb :: CheckedDatabaseSettings Postgres MyDb
myCheckedDb = defaultMigratableDbSettings @Postgres

myDb = unCheckDatabase myCheckedDb

testQuery = do
    conn <- connectPostgreSQL "host=localhost dbname=testdb"
    result <- runBeamPostgresDebug putStrLn conn $
        runSelectReturningList $
          select $ do
            users <- all_ $ dbUsers myDb
            --
            -- this query fails, because the tables `users` and `posts` are alias as 't0'
            --
            Pg.lateral_ (users) $ \user -> do
                post <- all_ (dbPosts myDb)
                guard_ (postUsername post ==. userName user)
                return (user, post)
    print result


-- Expected query:

-- SELECT "t1"."res0" AS "res0",
--        "t1"."res1" AS "res1",
--        "t1"."res2" AS "res2",
--        "t1"."res3" AS "res3",
--        "t1"."res4" AS "res4"
-- FROM "users" AS "t0"
-- CROSS JOIN LATERAL
--   (SELECT "t0"."id" AS "res0",
--           "t0"."name" AS "res1",
--           "t0"."email" AS "res2",
--           "t1"."id" AS "res3",
--           "t1"."username" AS "res4"
--    FROM "posts" AS "t1"
--    WHERE ("t1"."username") = ("t0"."name")) AS "t1";

-- Actual query:

-- SELECT "t1"."res0" AS "res0",
--        "t1"."res1" AS "res1",
--        "t1"."res2" AS "res2",
--        "t1"."res3" AS "res3",
--        "t1"."res4" AS "res4"
-- FROM "users" AS "t0"
-- CROSS JOIN LATERAL
--   (SELECT "t0"."id" AS "res0",
--           "t0"."name" AS "res1",
--           "t0"."email" AS "res2",
--           "t0"."id" AS "res3",
--           "t0"."username" AS "res4"
--    FROM "posts" AS "t0"
--    WHERE ("t0"."username") = ("t0"."name")) AS "t1"

-- *** Exception: SqlError {sqlState = "42703",
--                          sqlExecStatus = FatalError,
--                          sqlErrorMsg = "column t0.name does not exist",
--                          sqlErrorDetail = "",
--                          sqlErrorHint = "There is a column named \"name\" in table \"t0\", but it cannot be referenced from this part of the query."}