CREATE TABLE maillog(queue_id text, message_id text, uid text, client text);
CREATE TABLE to_data 
(queue_id text not null
, status text not null
, to_address text not null
, delays text not null
, comment text not null
, delay text not null
, dsn text not null
, relay text not null
, text_data text
, primary key (queue_id)
, foreign key (queue_id) references maillog  (queue_id)
);
