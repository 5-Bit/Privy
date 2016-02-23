create table login (
	user_id int primary key,
	username varchar(30),
	hash_password varchar(30)
);

create table device (
	user_id int,
	device_id varchar(30) primary key,
	foreign key (user_id) references login (user_id)
);

create table subscription (
	user_id int primary key,
	subscribed_to int,
	foreign key (user_id) references login (user_id)
);

create table social_media (
	user_id int primary key,
	facebook varchar(30),
	github varchar(30),
	google varchar(30),
	instagram varchar(30),
	linked_in varchar(30),
	pinterest varchar(30),
	snapchat varchar(30),
	soundcloud varchar(30),
	tumblr varchar(30),
	twitter varchar(30),
	vine varchar(30),
	youtube varchar(30),
	foreign key (user_id) references login (user_id)
);