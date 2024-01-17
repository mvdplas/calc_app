create or replace trigger "ORI_KALENDERS_T"
FOR INSERT OR UPDATE OR DELETE
ON ori_kalenders
COMPOUND TRIGGER
  l_sum_uren number(4);
  l_id       ori_kalenders.id%type;
  l_usr_id   ori_kalenders.usr_id%type;
  l_datum    ori_kalenders.datum%type;
     BEFORE STATEMENT IS
     BEGIN
       null;
     END BEFORE STATEMENT;
   
     --Executed before each row change- :NEW, :OLD are available
     BEFORE EACH ROW IS
     BEGIN
       l_id     := :new.id;
       l_usr_id := :new.usr_id;
       l_datum  := :new.datum;
       update ori_omzetten set gerealiseerde_uren = gerealiseerde_uren - :old.uren
       where usr_id = :old.usr_id
       and maand = to_char(:old.datum,'YYMM');
     END BEFORE EACH ROW;
   
     --Executed aftereach row change- :NEW, :OLD are available
     AFTER EACH ROW IS
     BEGIN
       null;
     END AFTER EACH ROW;
   
     --Executed after DML statement
     AFTER STATEMENT IS
     BEGIN
       select sum(uren)
       into l_sum_uren
       from ori_kalenders
       where usr_id = l_usr_id
       and to_char(datum,'YYMM') = to_char(l_datum,'YYMM');
       --
       update ori_omzetten
       set gerealiseerde_uren = l_sum_uren
       where usr_id = l_usr_id
       and maand = to_char(l_datum,'YYMM');
       if sql%rowcount = 0
       then
         insert into ori_omzetten (usr_id, maand, gerealiseerde_uren)
         values (l_usr_id, to_char(l_datum,'YYMM'),l_sum_uren);
       end if;
     END AFTER STATEMENT;

end;
/