
-- Alter table subscription add lat_last_pushed double precision;
-- Alter table subscription add long_last_pushed double precision;

Create or Replace function upsertSubscription (
    userID int, 
    uuid_str text, 
    lat_geo double precision,
    long_geo double precision)
returns void as $$
BEGIN
    with uuidSource as (
        Select regexp_split_to_table(uuid_str, ',')::uuid as id
    ),
    updated as (
        Update subscription 
        set last_time_pushed = NOW(),
            lat_last_pushed = lat_geo,
            long_last_pushed = long_geo
        from uuidSource
        where user_id = userID 
        and uuidSource.id = subscription.uuid
        returning *
    )
    Insert into subscription
    Select userID, uuidSource.id, NOW(), NOW(), lat_geo, long_geo
    from uuidSource
    left join updated on (updated.user_id = userID and uuidSource.id = updated.uuid)
    where updated.user_id is null;
END
$$ language plpgsql ;
