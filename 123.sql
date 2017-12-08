SELECT rowid FROM agents; --1
CREATE SEQUENCE orderno_sequence
increment by 1
start with 1000;--2
drop sequence orderno_sequence;
create or replace trigger cal
before insert on orders
for each row
declare
tp float;
td float;
od NUMBER(4,0);
begin
:new.ordno:=orderno_sequence.nextval;
select price into tp from products where pid=:new.pid;
select discount into td from customers where cid=:new.cid;
:new.dollars:=:new.qty*tp*(1-td/100);
end cal;
drop trigger cal;
truncate table orders
select * from orders;--3
select * from user_sequences where sequence_name=orderno_sequence
select orderno_sequence.currval from dual;
select orderno_sequence.nextval from dual;--4

set serveroutput on
declare
   type order_table_type is table of varchar(50)
   index by binary_integer;
   order_table order_table_type;
   cursor order_cursor is 
   select months,pid,qty,dollars from orders where ordno>1000 and ordno<1020;
   v_month orders.months%type;
   v_pid orders.pid%type;	
   v_qty orders.qty%type;
   v_dollars orders.dollars%type;
   v_loop number(3) :=1;
   v_data varchar(50);
   
   begin
   open  order_cursor;
   fetch order_cursor into v_month,v_pid,v_qty,v_dollars;
   while order_cursor%found loop
    v_data :=v_month||' '||v_pid||' '||v_qty||' '||v_dollars;
    order_table(v_loop):=v_data;
    dbms_output.put_line(order_table(v_loop));
    fetch order_cursor into v_month,v_pid,v_qty,v_dollars;
    v_loop :=v_loop+1;
   end loop;
   close order_cursor;
   end;--5
   
set serveroutput on
declare 
   BEGIN
  UPDATE products
    SET quantity = 200370
    WHERE pid = 'P08';
  IF SQL%NOTFOUND THEN
    INSERT INTO products (pid, quantity)
      VALUES ('P08',200370);
  END IF;
END;
select * from products;--6

create or replace procedure order_precedure(city in customers.city%type)
is
     cursor order_cur(ccity customers.city%type) is
     select o.cid,sum(o.dollars)from orders o,customers c
     where o.cid=c.cid and c.city=ccity
     group by o.cid;
     v_cid orders.cid%type;
     v_dollars orders.dollars%type;
  begin
    open order_cur(city);
    fetch order_cur into v_cid,v_dollars;
    while order_cur%found loop
    dbms_output.put_line('城市名称='||city);
    dbms_output.put_line('顾客编号='||v_cid||'  '||'订单总额='||v_dollars);
    fetch order_cur into v_cid,v_dollars;
    end loop;
    close order_cur;
 end;
 execute order_precedure('Duluth');--7
  
  
  
create or replace procedure order_judge(tablename in varchar2)
is
type order_cursor_type is ref cursor;
order_cursor order_cursor_type;
vname varchar2(20);
vdiscnt FLOAT;
vpercent NUMBER(3,0);
invalid_var exception;
begin
if(tablename='customers') then
open order_cursor for select cname,discount from customers;
fetch order_cursor into vname,vdiscnt;
while order_cursor%found loop
if(vdiscnt<10.00) then dbms_output.put_line(vname||'普通');
else dbms_output.put_line(vname||'vip');
end if;
fetch order_cursor into vname,vdiscnt;
end loop;
close order_cursor;
elsif(tablename='agents') then
open order_cursor for select aname,percent from agents;
fetch order_cursor into vname,vpercent;
while order_cursor%found loop
if(vpercent<6) then dbms_output.put_line(vname||'普通');
else dbms_output.put_line(vname||' vip');
end if;
fetch order_cursor into vname,vdiscnt;
end loop;
close order_cursor;
else raise invalid_var;
end if;
exception
when invalid_var then
dbms_output.put_line('input must be customer or agent');
end;
execute order_judge('agents');
select * from customers;--8

create table discnt_audit
(
change_by varchar2(8),
change_time date,
cid char(4),
old_discnt number(4,2),
new_discnt number(4,2)
);

create or replace trigger discnt_trigger
before insert or update of discount on customers
for each row
begin
if UPDATING then
insert into discnt_audit values(user,sysdate,:new.cid,:old.discount,:new.discount);
elsif inserting then
insert into discnt_audit values(user,sysdate,:new.cid,null,:new.discount);
end if;
end;

insert into customers values('C099','ABCD','lalala',0.00);
update customers set cname='DEFG' where cid='C099';
update customers set discount=0.95 where cid='C099';

select * from discnt_audit;--9

create or replace function qtycheck(pid char,psum number) return boolean
is
storagenum products.quantity%type;
cursor cur is select p.quantity into storagenum from products p where p.pid=pid;
begin
open cur;
fetch cur into storagenum;
close cur;
if(storagenum>psum) then
dbms_output.put_line('没有超出库存量');
return true;
else
dbms_output.put_line('warning!!,超出库存量');
return false;
end if;
end;

declare
a boolean;
begin
a:=qtycheck('P01',40);
end;

declare
a boolean;
begin
a:=qtycheck('P03',9999999990);
end;












