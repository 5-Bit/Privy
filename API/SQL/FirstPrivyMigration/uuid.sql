
Select  
-- This is a drop in for json_object_agg
    ('{' || string_agg('"' || info_type || '": ' || (privy_user.social_information->>info_type), ',') || '}' )::json as USER_JSON
from privy_user
inner join privy_uuids 
    on privy_user.id = privy_uuids.user_id
where 
    privy_uuids.id::text = ANY (string_to_array('c9cd365f-00fa-4b67-84b1-b46283922e40,c3fe3704-015c-48c4-a5f3-ebd360c34dd4', ','))
group by privy_user.id
