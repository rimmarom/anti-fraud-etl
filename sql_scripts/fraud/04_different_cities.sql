 DROP VIEW if exists v_tmp_card_num;
        CREATE VIEW v_tmp_card_num as
        select
        card_num,
        transaction_date,
        row_number() over (partition by card_num order by transaction_date ) as row
        from (
            select 
            terminal_city,
            card_num,
            transaction_date,
            AGE(transaction_date, LAG(transaction_date, 1, transaction_date) OVER (PARTITION BY card_num)) as dt,
            LEAD(terminal_city) OVER (PARTITION BY card_num) as next_city,
            LAG(terminal_city) OVER (PARTITION BY card_num) as prev_city
            from (
                select 
                t1.terminal_city as terminal_city ,
                t2.card_num as card_num,
                t2.transaction_date as transaction_date
                from dwh_dim_terminals t1
                inner join dwh_fact_transactions t2
                on t1.terminal_id = t2.terminal
             )
            where card_num in (
                select 
                card_num
                from (
                    select 
                    t1.terminal_city as terminal_city ,
                    t2.card_num as card_num,
                    t2.transaction_date as transaction_date
                    from dwh_dim_terminals t1
                    inner join dwh_fact_transactions t2
                    on t1.terminal_id = t2.terminal
                 )
            group by card_num
            having count(distinct terminal_city) > 1
            )
        order by card_num, transaction_date
  ) tmp_table
    where (next_city <> terminal_city or prev_city <> terminal_city )
    and dt <= INTERVAL '1 hour';

INSERT INTO REP_FRAUD (
                event_dt,passport,fio,phone,event_type
                                          ) 
        select 
                event_dt,passport,fio,phone,event_type
                from (
                select 
                t2.transaction_date as event_dt,
                t1.passport_num as passport,
                CONCAT(t1.last_name, ' ', t1.first_name, ' ', t1.patronymic) AS fio,
                t1.phone,
                'Совершение операций в разных городах в течение одного часа.' as event_type
                from (
                    select distinct
                    t4.first_name as first_name,
                    t4.last_name as last_name,
                    t4.patronymic as patronymic,
                    t4.phone as phone,
                    t4.passport_num as passport_num,
                    t1.card_num
                    from dwh_fact_transactions t1
                    inner join dwh_dim_cards t2
                    on t1.card_num = t2.card_num
                    inner join dwh_dim_accounts t3
                    on t2.account = t3.account
                    inner join dwh_dim_clients t4
                    on t3.client = t4.client_id
                    where t2.card_num in 
                        (
                        select 
                        card_num
                        from v_tmp_card_num
                        where row = 1
                        ) 
       ) t1
     inner join v_tmp_card_num t2
     on t1.card_num = t2.card_num);