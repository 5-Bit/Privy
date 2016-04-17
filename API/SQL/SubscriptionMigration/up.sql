Create Table APNS_Token (
    id SERIAL Primary Key,
    user_id int REFERENCES privy_user(id),
    APNS_device_token text,
    UNIQUE (APNS_device_token)
); 

Create Table Subscription (
    -- for each user, the uuids they are subscribed to.
    user_id int PRIMARY KEY REFERENCES privy_user(id),
    uuid uuid REFERENCES privy_uuids(id),
    last_time_pushed timestamptz default null
);

-- Modify this at then end
Alter Table privy_uuids add column last_modified_date timestamptz;

Alter Table APNS_Token Owner to appuser;
Alter Table Subscription Owner to appuser;


CREATE OR REPLACE function upsertAPNSForUser(int, text) returns void 
as $$
begin
    update apns_token set user_id = $1 where apns_device_token = $2;
    if found then
        return;
    end if;
    begin
        insert into apns_token (user_id, apns_device_token) values ($1, $2);
    exception when unique_violation then
            update apns_token set user_id = $1 where apns_device_token = $2;
    end;
end;

$$ language plpgsql;

/*
    Plan of attack:
    1. Set up route for UUID refreshes
    2. Cause subscriptions for the UUID lookup route
    3. When user json is saved, detect what things keys are being updated
    3.1 When saving user JSON, save last_modified_date column for each modified_privy_uuids
    3.2 Asynchronously trigger APNS updates to fire immediately
    3.3 When a user requests the information, then it de-marked for sync
    4. 
 */

