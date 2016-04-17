

START TRANSACTION;

CREATE DOMAIN dom_email TEXT CHECK (
    LENGTH(VALUE) > 3 AND
    LENGTH(VALUE) < 254 AND
    VALUE ~ '^.+@.+$'
);

Create Table privy_user (
    id SERIAL primary key,
    email dom_email UNIQUE,
    first_name text,
    last_name text,
    phone_number text, 
    password_hash text,
    apple_push_notifcation_id text,
    social_information json
);

Create Table privy_uuids (
    id uuid PRIMARY KEY DEFAULT (uuid_generate_v4()), 
    user_id int REFERENCES privy_user (id),
    info_type text
    CHECK (info_type in ('basic',
                     'user',
                     'social',
                     'business',
                     'developer',
                     'media', 
                     'blogging'))
);


Alter domain dom_email OWNER TO appuser;
Alter Table privy_user OWNER TO appuser;
Alter Table privy_uuids OWNER TO appuser;

COMMIT;
