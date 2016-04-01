BEGIN 
    LOCK TABLE password_reset in SHARE ROW EXCLUSIVE MODE;
    ;with upsert as (
        Update password_reset 
        Set valid_til = NOW(),
            password_reset_token = uuid_generate_v4()
        where user_id = $1
        RETURNING *
    )
    Insert into password_reset (user_id)
    values ($1) 
    where not exists (Select * from upsert)
    RETURNING 
COMMIT;
