Create or replace function getUserSubData(int) returns setof json as $$
begin
    return Query Select
    -- This is a drop in for json_object_agg. I need to figure out how to build that...
    ('{' ||
        string_agg(Distinct '"' || info_type || '": '
            || (privy_user.social_information->>info_type), ',')
        || '}' )::json as USER_JSON

    from privy_user
    inner join privy_uuids
    on privy_user.id = privy_uuids.user_id
    inner join subscription 
    on subscription.uuid = privy_uuids.id 
    where
    subscription.user_id = $1
    group by privy_user.id, privy_uuids.user_id
    order by max(subscription.created_date) desc;
end;
$$ language plpgsql
