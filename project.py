#!/usr/bin/env python
# coding: utf-8

import psycopg2
import json 
import pandas as pd
from sqlalchemy import create_engine
import os
import shutil
import glob


data = "data"  # Папка с исходными файлами
archive_dir = os.path.join(data, "archive")  # Папка для архива внутри data

# Создала папку archive, если её нет 
os.makedirs(archive_dir, exist_ok=True)


# ## Подключаемся к DBeaver, затем к схеме catchscam, в которую будут премещены все таблицы


with open('db_config.json') as f:
    db_config = json.load(f)



sql_alch_conn = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}:{db_config['port']}/{db_config['dbname']}"


conn = psycopg2.connect(**db_config)
cursor = conn.cursor()


cursor.execute('create schema if not exists catchscam')
cursor.execute('set search_path to catchscam')
conn.commit()
# Выполняет SQL-запрос из файла
def run_sql(path):
    with open(path, encoding="utf-8") as f:
        cursor.execute(f.read())

# ## Считывтаель CSV файла

# ### Все файлы для выгрузки берем из папки data, path - имя самого файла. Новые таблицы создаю в схеме catchscam.
# ### После обработки файла, меняю его расширение и переношу в папку archive, лежащую в папке data




def csv2sql(path, **sql_con_config):
    file_path = os.path.join(data, path)
    df = pd.read_csv(file_path, sep=";")
    df['amount'] = df['amount'].str.replace(',', '.').astype(float)
    df.to_sql(**sql_con_config )
    cursor.execute('ALTER TABLE dwh_fact_transactions ALTER COLUMN transaction_date TYPE TIMESTAMP USING transaction_date::TIMESTAMP')
    conn.commit()
    new_name = file_path + ".backup"
    os.rename(file_path, new_name)
    shutil.move(new_name, os.path.join(archive_dir, os.path.basename(new_name)))


# ### Считывтаель XLSX файла




def xlsx2sql(path, **sql_con_config):
    file_path = os.path.join(data, path)
    df = pd.read_excel(file_path)
    df.to_sql(**sql_con_config )
    new_name = file_path + ".backup"
    os.rename(file_path, new_name)
    shutil.move(new_name, os.path.join(archive_dir, os.path.basename(new_name)))


# ### Создание таблиц в схеме catchscam такие же, как в схеме bank



def create_dwh_from_bank():
    cursor.execute("""
                    CREATE TABLE if not exists dwh_dim_clients AS 
                    select * from bank.clients
                   """)
    cursor.execute("""
                    ALTER TABLE dwh_dim_clients ALTER COLUMN passport_valid_to TYPE TIMESTAMP
                   """)
    cursor.execute("""
                    CREATE TABLE if not exists dwh_dim_cards AS
                    select * from bank.cards
                   """)
    cursor.execute("""
                    CREATE TABLE if not exists dwh_dim_accounts AS
                    select * from bank.accounts
                   """)
    cursor.execute('ALTER TABLE dwh_dim_accounts ALTER COLUMN valid_to TYPE TIMESTAMP')
    conn.commit()


# ### Создание dwh_terminals как stg_terminals, но с дабавлением колонки create_dt, update_dt



def dwh_terminals():
    cursor.execute("""
                CREATE TABLE dwh_dim_terminals as
                select * from stg_terminals
                   """)
    cursor.execute("""
               ALTER TABLE dwh_dim_terminals
               ADD COLUMN create_dt TIMESTAMP;
                   """)
    cursor.execute("""
               UPDATE dwh_dim_terminals 
               SET create_dt = (select distinct transaction_date::date from dwh_fact_transactions)::TIMESTAMP
                   """)
    cursor.execute("""
               ALTER TABLE dwh_dim_terminals
               ADD COLUMN update_dt TIMESTAMP NULL;
                   """)
    conn.commit()

# ## Выявление мошеннических операций
# #### Подбор сумм делала так: мошенническая операция, если число операций 4 и более, то есть минимальный случай REJECT REJECT REJECT SUCCESS в течении 20 мин с уменьшением суммы
# #### Разные города: вывожу все операции, которые произошли в течении часа в разных городах, то есть, если операции произошли в  Москва Саратов Москва и интервал между ними менее часа, то вывожу 3 строки 


def create_report():
    cursor.execute("""
                CREATE TABLE if not exists REP_FRAUD(
                    id serial primary key,
                    event_dt timestamp,
                    passport varchar(128),
                    fio varchar(128),
                    phone varchar(128),
                    event_type varchar(128),
                    report_dt timestamp default current_timestamp
                    )
                
    """)
    conn.commit()
# Выполняет SQL-запрос из файла
# Поиск мошенничества: каждый тип — отдельный файл в sql_scripts/fraud
FRAUD_CHECKS = [
    "01_passport_expired",
    "02_passport_blocked",
    "03_invalid_contract",
    "04_different_cities",
    "05_amount_guessing",
]

def update_report():
    for check in FRAUD_CHECKS:
        run_sql(f"sql_scripts/fraud/{check}.sql")
    conn.commit()





def delete_tmp_tables():
    cursor.execute(" drop table if exists dwh_fact_transactions CASCADE")
    cursor.execute(" drop table if exists stg_terminals CASCADE")
    cursor.execute(" drop table if exists dwh_fact_passport_blacklist CASCADE") 
    cursor.execute(" drop table if exists dwh_dim_terminals CASCADE") 
    cursor.execute(" drop table if exists stg_terminals_new CASCADE")
    cursor.execute(" drop table if exists stg_cards_new CASCADE")
    cursor.execute(" drop table if exists stg_accounts_new CASCADE")
    cursor.execute(" drop table if exists stg_clients_new CASCADE")
    cursor.execute(" drop table if exists stg_terminals_del CASCADE")
    cursor.execute(" drop table if exists stg_cards_del CASCADE")
    cursor.execute(" drop table if exists stg_accounts_del CASCADE")
    cursor.execute(" drop table if exists stg_clients_del CASCADE")
    cursor.execute(" drop table if exists stg_terminals_update CASCADE")
    conn.commit()


# ## Запускаем функции в нужном порядке




dates = ['01032021','02032021', '03032021' ]
create_dwh_from_bank()





for el in dates:
    csv2sql(
                f"transactions_{el}.txt",
                name= 'dwh_fact_transactions', 
                con=create_engine(sql_alch_conn), 
                schema="catchscam", 
                if_exists='replace', 
                index=False
               )

    xlsx2sql(
                f"terminals_{el}.xlsx",
                name= 'stg_terminals', 
                con=create_engine(sql_alch_conn), 
                schema="catchscam", 
                if_exists='replace', 
                index=False
               )

    xlsx2sql(
                f"passport_blacklist_{el}.xlsx",
                name= 'dwh_fact_passport_blacklist', 
                con=create_engine(sql_alch_conn), 
                schema="catchscam", 
                if_exists='replace', 
                index=False
               )

    

    dwh_terminals()
    # Обновление таблиц истории (SCD2)
    run_sql("sql_scripts/scd2/01_create_hist.sql")
    run_sql("sql_scripts/scd2/02_stg_new.sql")
    run_sql("sql_scripts/scd2/03_stg_deleted.sql")
    run_sql("sql_scripts/scd2/04_stg_updated.sql")
    run_sql("sql_scripts/scd2/05_update_hist.sql")
    conn.commit()
    create_report()
    update_report()
    delete_tmp_tables()


# ## Итог

# ### В табличке  rep_fraud 15 записей мошеннических операций
# ### В табличке историй терминалов - 1 удаленных запись и 4 завершенных, всего записей 155


