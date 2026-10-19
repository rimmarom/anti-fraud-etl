CREATE TABLE stg_terminals_update as 
            select 
                t2.terminal_id,
                t2.terminal_type,
                t2.terminal_city,
                t2.terminal_address
            from v_dwh_dim_terminals_his t1
            inner join dwh_dim_terminals t2
            on t1.terminal_id = t2.terminal_id
            and ( t1.terminal_type <> t2.terminal_type 
                  or t1.terminal_address <> t2.terminal_address
                  or t1.terminal_city <> t2.terminal_city);