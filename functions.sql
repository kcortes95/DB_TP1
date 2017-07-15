create table muestra (
        country text,
        postalcode text,
        city text,
        status text check (status in ('ACTIVO', 'EXPIRADO')),
        quantity integer,
        primary key (postalcode,country,status)
);

select inserta_estado('AUSTRALIA','2142');
select * from muestra;

select inserta_estado('2000', '2');
select * from muestra

delete from muestra

create or replace function inserta_estado(pais in muestra.country%type, cp in muestra.postalcode%type) returns void as $$
        
        declare city_exist domains.registrant_city%type;
        
        begin
                
                select registrant_city into city_exist
                from domains
                where registrant_country = pais and registrant_postalcode = cp;
                
                if city_exist is null then
                        raise notice 'Imposible continuar';
                        return;
                end if;
        
                insert into muestra values(pais, cp, middle_value_active(pais,cp), 'ACTIVO', get_tot(pais,cp,current_date,'ACTIVO'));
                insert into muestra values(pais, cp, middle_value_expired(pais,cp), 'EXPIRADO', get_tot(pais,cp,current_date,'EXPIRADO'));
        end;
$$ language plpgsql;

create or replace function middle_value_expired(pais in domains.registrant_city%type, pc in domains.registrant_postalcode%type) returns domains.registrant_city%type as $$
        declare elcursor_expired cursor for (select registrant_city from domains where registrant_country = pais and registrant_postalcode = pc and expiresdate < current_date order by registrant_city);
        declare cursor_tipo domains.registrant_city%type;
        declare counter integer;
        declare middle_v integer;
        
        begin
                counter := 0;
                open elcursor_expired;
                
                select count(registrant_city)/2 into middle_v
                from domains
                where registrant_country = pais and registrant_postalcode = pc and expiresdate < current_date;
                
                loop
                
                        fetch elcursor_expired into cursor_tipo;
                        exit when not found;
                        
                        if (counter = middle_v) then
                                exit;
                        end if;
                                        
                        raise notice 'el valor de counter: %',counter;
                        counter := counter + 1;
                        
                end loop;
                
                close elcursor_expired;
                return cursor_tipo;
               
        end;
$$ language plpgsql;

create or replace function middle_value_active(pais in domains.registrant_city%type, pc in domains.registrant_postalcode%type) returns domains.registrant_city%type as $$
        declare elcursor cursor for (select registrant_city from domains where registrant_country = pais and registrant_postalcode = pc and expiresdate > current_date order by registrant_city);
        declare cursor_tipo domains.registrant_city%type;
        declare counter integer;
        declare middle_v integer;
        
        begin
                counter := 0;
                open elcursor;
                
                select count(registrant_city)/2 into middle_v
                from domains
                where registrant_country = pais and registrant_postalcode = pc and expiresdate > current_date;
                
                loop
                
                        fetch elcursor into cursor_tipo;
                        exit when not found;
                        
                        if (counter = middle_v) then
                                exit;
                        end if;
                                        
                        raise notice 'el valor de counter: %',counter;
                        counter := counter + 1;
                        
                end loop;
                close elcursor;
                return cursor_tipo;
                
        end;
$$ language plpgsql;

create or replace function get_tot(pais in muestra.country%type, cp in muestra.postalcode%type, dt in domains.expiresdate%type, status_type in text) returns integer as $$
        declare total_count integer;
        begin
        
                if status_type = 'ACTIVO' then
                        select count(*) into total_count
                        from domains
                        where domains.registrant_country = pais and registrant_postalcode = cp and expiresdate > dt;
                else
                        select count(*) into total_count
                        from domains
                        where domains.registrant_country = pais and registrant_postalcode = cp and expiresdate < dt;
                end if;
                
                return total_count;
        
        end;
$$ language plpgsql;

create or replace function nvecinos(pais in muestra.country%type, cp in muestra.postalcode%type, n in integer) returns void as $$
	begin
	       delete from muestra;
		if n < 0 then
	               return;
		else
		      
		       if (select exists(select domains.registrant_postalcode from domains where domains.registrant_country =pais)) then
		              perform insertnvecinos(pais,cp,n+1);
		       else
		              perform insertnvecinos(pais,cp,n+2);
		       end if;
                end if;
        end;
$$ language plpgsql;

create or replace function insertnvecinos(pais in muestra.country%type, cp in muestra.postalcode%type, n in integer) returns void as $$
        declare acp muestra.postalcode%type;
        declare mycursor cursor for select distinct registrant_postalcode from domains where domains.registrant_country = pais and domains.registrant_postalcode >= cp order by domains.registrant_postalcode asc limit n;
        begin
                open mycursor;
                     loop
                        fetch mycursor into acp;
                        exit when not found;
                        perform inserta_estado(pais,acp);
                end loop;

                
        end;
$$ language plpgsql;

select nvecinos('UNITED STATES','20003',4);
select * from muestra
order by postalcode, status desc;

select nvecinos('ARGENTINA','9405',8);
select * from muestra
order by postalcode, status desc;

SELECT nvecinos('ARGENTINA','55555',2); 
select * from muestra
order by postalcode, status desc;

delete from muestra