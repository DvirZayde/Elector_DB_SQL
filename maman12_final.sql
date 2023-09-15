-- A
create table election
(edate date, 
kno int, 
primary key(edate));

create table party
(pname varchar(20), 
symbol varchar(5), 
primary key(pname));

create table city
(cid numeric(5,0), 
cname varchar(20), 
region varchar(20),
primary key(cid));

create table running
(edate date, 
pname varchar(20), 
chid numeric(5,0),
totalvotes int default 0,
primary key(edate, pname),
foreign key(pname) references party,
foreign key(edate) references election);

create table votes
(cid numeric(5,0), 
pname varchar(20), 
edate date,
nofvotes int NOT NULL,
CHECK (nofvotes>0),
primary key(cid, edate, pname),
foreign key(edate, pname) references running,
foreign key(cid) references city);

--B

create or replace function trigf1()
returns trigger as $$
DECLARE
newVotes int;
begin 
if TG_OP='INSERT' then
begin
	newVotes=new.nofvotes;
end;
end if;
if TG_OP='UPDATE' then
begin
	newvotes=new.nofvotes- old.nofvotes;
end;
end if;

begin
update running
set totalvotes=totalvotes+newVotes
where pname=new.pname and edate=new.edate;
END;
return new;
END;
$$ language plpgsql;


CREATE TRIGGER T1
AFTER INSERT OR UPDATE ON votes
FOR EACH ROW EXECUTE PROCEDURE
trigf1();

--c

insert into election values
('2019-04-09', 1),
('2019-09-17', 2),
('2020-03-02', 3),
('2021-03-23', 4),
('2022-11-01', 5);

insert into party values
('nature party', 'np'),
('science group', 'sg'),
('life party', 'lp'),
('art group', 'ag'),
('lost group', 'lg');

insert into city values
(22 , 'ryde end', 'north'),
(77, 'east strat', 'south'),
(33, 'grandetu', 'center'),
(88, 'royalpre', 'hills'),
(11, 'carlpa', 'hills'),
(44, 'lommont', 'north'),
(66, 'grand sen', 'south'),
(99, 'kingo haven', 'hills'),
(55, 'el munds', 'south');

insert into running values
('2019-04-09', 'nature party', 12345),
('2019-04-09', 'life party', 54321),
('2019-04-09', 'lost group', 34567),
('2019-09-17', 'lost group', 76543),
('2019-09-17', 'art group', 67890),
('2020-03-02', 'science group', 90876),
('2020-03-02', 'nature party', 55555),
('2020-03-02', 'life party', 54321);

insert into votes values
(22, 'nature party', '2020-03-02', 100),
(22, 'science group', '2020-03-02', 30),
(22, 'life party', '2020-03-02', 500),
(77, 'nature party', '2020-03-02', 300),
(77, 'science group', '2020-03-02', 150),
(77, 'life party', '2020-03-02', 25),
(33, 'nature party', '2020-03-02', 13),
(33, 'science group', '2020-03-02', 740),
(33, 'life party', '2020-03-02', 670);




-- D1
select pname,nofvotes
from votes natural join party natural join city
where cname='ryde end' and edate='2020-03-02';

--D2
select pname, region, sum(nofvotes)
from votes natural join city natural join election
where kno=3
group by pname,region;

--D3
select  cname, region
from city as p
where cname not in 
	(select cname
	from city natural join votes
	where pname='life party');
	
--D4
select kno, edate, count(*) as noParty
from election natural join running
group by kno, edate
having count(*)>=ALL
	(select count(*)
	from running
	group by edate);
	
--D5
select distinct pname, totalvotes
from (election natural join running natural join votes natural join city) as aa
where kno=3 and pname not in
	(select pname
	from city natural join votes
	where region='hills') 
and totalvotes<=ALL
	(select totalvotes
	from running
	where pname=aa.pname);
	
--d6
select pname, totalvotes
from election natural join running
where kno=3 and totalvotes in
	(select max(totalvotes)
	from election natural join running
	where kno=3 and totalvotes<ANY
		(select totalvotes
		from election natural join running
		where kno=3));
		
--d7
select distinct x.pname, y.pname
from party as x ,party as y 
where x.pname<y.pname and x.pname not in
	(select pname
	from running
	where edate not in
		(select edate
		from running
		where pname=y.pname))
and y.pname not in
	(select pname
	from running
	where edate not in
		(select edate
		from running
		where pname=x.pname));