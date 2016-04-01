Create Table password_reset (
    password_reset_token uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
    user_id int REFERENCES privy_user(id),
    valid_til timestamptz DEFAULT (NOW())
);

CREATE OR REPLACE FUNCTION getResetToken(int) RETURNS UUID as
$$
DECLARE 
    newuuid uuid := uuid_generate_v4();
BEGIN  
    LOCK TABLE password_reset in SHARE ROW EXCLUSIVE MODE;
    with upsert as (
        Update password_reset 
        Set valid_til = NOW(),
            password_reset_token = newuuid
            where user_id = $1
        RETURNING *
    )
    Insert into password_reset (user_id, password_reset_token)
    Select $1, newuuid 
    where not exists (Select * from upsert);

    return newuuid;
END
$$ LANGUAGE plpgsql VOLATILE; 
Alter table password_reset owner to appuser;
