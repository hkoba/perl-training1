CREATE TABLE maillog(queue_id text, message_id text, uid text, client text);
CREATE TABLE to_data 
(queue_id text not null
, status text null
, to_address text null
, delays text null
, comment text null
, delay text null
, dsn text null
, relay text null
, text_data text null
, foreign key (queue_id) references maillog  (queue_id)
);
