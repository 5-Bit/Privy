Create or replace function getUserSubData(int) returns setof json as $$
begin
    return Query
    with maxGeoData as (
        Select
            ROW_NUMBER() OVER(Partition by UUID Order by created_date desc) as num,
            COALESCE(lat_last_pushed::text, 'null') as latitude, 
            COALESCE(long_last_pushed::text, 'null') as longitude,
            uuid
        from 
            Subscription 
    )
    Select
    -- This is a drop in for json_object_agg. I need to figure out how to build that...
    ('{' ||
        string_agg(Distinct '"' || info_type || '": '
            || (privy_user.social_information->>info_type), ',') ||
            ', "uuid": "' || max(privy_uuids.id::text) || '"' ||
            ', "location": {' ||
            '"latitude": ' || max(
                CASE 
                    WHEN num = 1 then latitude
                ELSE NULL END
            ) || ', ' ||
            '"longitude": ' || max(
                CASE 
                    WHEN num = 1 then longitude
                ELSE NULL END
            ) || '}'
        || '}' )::json as USER_JSON

    from privy_user
    inner join privy_uuids
        on privy_user.id = privy_uuids.user_id
    inner join subscription 
        on subscription.uuid = privy_uuids.id 
    inner join maxGeoData 
        on subscription.uuid = maxGeoData.uuid

    where subscription.user_id = $1
    group by privy_user.id, privy_uuids.user_id
    order by max(subscription.created_date) desc;
end;
$$ language plpgsql

