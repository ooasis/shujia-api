import os
import mysql.connector
import psycopg2
import psycopg2.extras
import logging
from datetime import date


LOG = logging.getLogger("relay")
LOG.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter(formatter)
LOG.addHandler(ch)


def pg_context():
    return psycopg2.connect(
        host="localhost", user="sj", password="sj", dbname="sj"
    )


def insert_ref(pg_context, ref, table, name):
    with pg_context.cursor() as cursor:
        cursor.execute(
            "insert into %s(name, inserted_at, updated_at) values('%s', now(), now()) returning id"
            % (table, escape(name))
        )
        new_id = cursor.fetchone()[0]
        ref["new_id"] = new_id
        return new_id


def insert_xref(pg_context, table, field1, field2, id1, id2):
    with pg_context.cursor() as cursor:
        cursor.execute(
            "insert into %s(%s, %s) values(%s, %s)" % (table, field1, field2, id1, id2)
        )


def insert_inventory(pg_context, catalog_id, copy_seq):
    with pg_context.cursor() as cursor:
        cursor.execute(
            "insert into inventory(catalog_id, copy_seq, inserted_at, updated_at) values(%d, %d, now(), now())"
            % (catalog_id, copy_seq)
        )


def get_ref_id(pg_context, cache, raw_id, table):
    ref = cache.get(raw_id)
    if ref:
        id = ref.get("new_id")
        if id is None:
            name = ref.get("NAME")
            new_id = insert_ref(pg_context, ref, table, name)
            return new_id
        else:
            return id
    else:
        print("Id %s not found in %s" % (raw_id if raw_id else "null", table))
        return None


def insert_book(
    pg_context,
    call_id,
    name,
    alt_name,
    edition,
    language,
    fomat,
    publish_date,
    publisher_id,
):
    with pg_context.cursor() as cursor:
        try:
            cursor.execute(
                "insert into catalog(call_id, name, alt_name, edition, lang, format, publish_date, publisher_id, inserted_at, updated_at) values('%s', '%s', '%s', '%s', '%s', '%s', %s, %s, now(), now()) returning id"
                % (
                    call_id,
                    name,
                    alt_name,
                    edition,
                    language,
                    fomat,
                    publish_date,
                    publisher_id if publisher_id else "null",
                )
            )
            return cursor.fetchone()[0]
        except psycopg2.IntegrityError as ie:
            return None


def mysql_conn():
    return mysql.connector.connect(
        host="", user="", passwd="", database=""
    )


def fetch_table(conn, table):
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM %s" % table)
    rslt = cursor.fetchall()
    d = {}
    for v in rslt:
        d[v["ID"]] = v
    return d


def get_language(city):
    if city in ["上海", "江蘇", "北京", "中國南京", "南京", "浙江", "深圳市"]:
        return "sc"
    else:
        return "cn"


def escape(s):
    return s.replace("'", "''") if s else s


if __name__ == "__main__":

    mysql_conn = mysql_conn()
    subjects = fetch_table(mysql_conn, "subject")
    publishers = fetch_table(mysql_conn, "publisher")
    authors = fetch_table(mysql_conn, "author")
    translators = fetch_table(mysql_conn, "author")
    books = fetch_table(mysql_conn, "book")
    mysql_conn.close()

    with pg_context() as pg_context:
        for book in books.values():
            call_id = book["CALL_ID"]
            name = escape(book["CHN_NAME"])
            alt_name = escape(book["ENG_NAME"])
            edition = book["EDITION"]
            language = "tc"
            fomat = "book"
            publish_date = (
                "'%s'" % date(year=book["PUBLISHED_YEAR"], month=1, day=1)
                if book["PUBLISHED_YEAR"] and book["PUBLISHED_YEAR"] > 0
                else "null"
            )
            publisher_id = get_ref_id(
                pg_context, publishers, book["PUBLISHER_ID"], "publisher"
            )
            catalog_id = insert_book(
                pg_context,
                call_id,
                name,
                alt_name,
                edition,
                language,
                fomat,
                publish_date,
                publisher_id,
            )
            if catalog_id is None:
                pg_context.rollback()
                continue

            subject1 = book["SUBJECT_ID"]
            subject_id = get_ref_id(pg_context, subjects, subject1, "subject")
            if subject_id:
                insert_xref(
                    pg_context,
                    "catalog_subjects",
                    "catalog_id",
                    "subject_id",
                    catalog_id,
                    subject_id,
                )

            author = book["AUTHOR_ID"]
            author_id = get_ref_id(pg_context, authors, author, "author")
            if author_id:
                insert_xref(
                    pg_context,
                    "catalog_authors",
                    "catalog_id",
                    "author_id",
                    catalog_id,
                    author_id,
                )

            eng_author = book["ENGLISH_AUTHOR_ID"]
            if eng_author and eng_author > 0 and eng_author != author:
                eng_author_id = get_ref_id(pg_context, authors, eng_author, "author")
                if eng_author_id:
                    insert_xref(
                        pg_context,
                        "catalog_authors",
                        "catalog_id",
                        "author_id",
                        catalog_id,
                        eng_author_id,
                    )

            translator = book["TRANSLATOR_ID"]
            if translator and translator > 0:
                translator_id = get_ref_id(
                    pg_context, translators, translator, "translator"
                )
                if translator_id:
                    insert_xref(
                        pg_context,
                        "catalog_translators",
                        "catalog_id",
                        "translator_id",
                        catalog_id,
                        translator_id,
                    )

            quantity = book["QTY"]
            if quantity and quantity > 0:
                for i in range(1, quantity + 1):
                    insert_inventory(pg_context, catalog_id, i)

            pg_context.commit()

