
-- This does deletes all the subscriptions that a given user has to the user that the other 
-- user
Create or Replace function removeSubscriptionsForuser(userID int, other_user_uuid uuid)
returns SETOF subscription as $$
DECLARE
Other_user_id int;
BEGIN
    other_user_id = (Select Max(user_id) from privy_uuids where id = other_user_uuid limit 1);
    RETURN QUERY 
    with other_uuids as (
        Select id from privy_uuids 
        where user_id = other_user_id
    )
    Delete from subscription
    using other_uuids
    where subscription.user_id = userID 
    and other_uuids.id = subscription.uuid
    RETURNING subscription.*;
END; $$ language plpgsql;

