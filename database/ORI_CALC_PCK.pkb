CREATE OR REPLACE package body "ORI_CALC_PCK" as

procedure standaard_urencalc (o_min_charge_uren_jr  out number
                             ,o_min_charge_uren_mnd out number
                             ,o_max_charge_uren_jr  out number
                             ,o_max_charge_uren_mnd out number) is

  cursor c_par is
    select vakantiedagen
    ,      aantal_daguren
    ,      ziektedagen
    ,      overig_verlof
    ,      leegloop
    ,      totaal_uren
    ,      eerste_maand_berekening
    ,      laatste_maand_berekening
    from   ori_parameters
    where  usr_fk = (select id from ori_users where username = v('APP_USER'));
  r_par                      c_par%rowtype;
  l_vakantiedagen            number;
  l_aantal_daguren           number;
  l_ziektedagen              number;
  l_overig_verlof            number;
  l_leegloop                 number;
  l_werkzame_uren            number;
  l_eerste_maand_berekening  number;
  l_laatste_maand_berekening number;
  l_aantal_maanden           number;

  l_totaal_uren           number := 2080;
  l_totaal_vakantie_uren  number;
  l_totaal_ziekte_uren    number;
  l_totaal_overige_verlof number;
  l_totaal_leegloop       number;
  l_min_beschikbaar       number;
  l_min_charge_uren_jr    number;
  l_min_charge_uren_mnd   number;
  l_max_charge_uren_jr    number;
  l_max_charge_uren_mnd   number;
begin
  open c_par;
  fetch c_par into r_par;
  close c_par;
  --
  l_vakantiedagen            := r_par.vakantiedagen;
  l_aantal_daguren           := r_par.aantal_daguren;
  l_ziektedagen              := r_par.ziektedagen;
  l_overig_verlof            := r_par.overig_verlof;
  l_leegloop                  := r_par.leegloop;
  l_werkzame_uren            := r_par.totaal_uren;
  l_eerste_maand_berekening  := r_par.eerste_maand_berekening;
  l_laatste_maand_berekening := r_par.laatste_maand_berekening;
  l_aantal_maanden := (l_laatste_maand_berekening - l_eerste_maand_berekening) + 1;
  --
  l_totaal_vakantie_uren  := l_vakantiedagen * l_aantal_daguren;
  l_totaal_ziekte_uren    := l_ziektedagen * l_aantal_daguren;
  l_totaal_overige_verlof := l_overig_verlof * l_aantal_daguren;
  l_totaal_leegloop       := l_leegloop * l_aantal_daguren;

  l_min_beschikbaar     := l_totaal_uren - l_totaal_vakantie_uren - l_totaal_ziekte_uren - l_totaal_overige_verlof - l_totaal_leegloop;
  l_min_charge_uren_jr  := ((l_min_beschikbaar / 40) * l_werkzame_uren)/12 * l_aantal_maanden;
  l_min_charge_uren_mnd := l_min_charge_uren_jr / l_aantal_maanden;
  l_max_charge_uren_jr  := (l_min_beschikbaar + l_totaal_leegloop + l_totaal_ziekte_uren)/40 * l_werkzame_uren/12 * l_aantal_maanden;
  l_max_charge_uren_mnd := l_max_charge_uren_jr / l_aantal_maanden;
  --
  o_min_charge_uren_jr  := l_min_charge_uren_jr;
  o_min_charge_uren_mnd := l_min_charge_uren_mnd;
  o_max_charge_uren_jr  := l_max_charge_uren_jr;
  o_max_charge_uren_mnd := l_max_charge_uren_mnd;
end standaard_urencalc;

function fn_standaard_urencalc return tt_standaard_urencalc pipelined as
  urencalc_row tr_standaard_urencalc;
begin
  standaard_urencalc(urencalc_row.min_charge_uren_jr
                    ,urencalc_row.min_charge_uren_mnd
                    ,urencalc_row.max_charge_uren_jr
                    ,urencalc_row.max_charge_uren_mnd);
  pipe row(urencalc_row);
  --
  return;
end fn_standaard_urencalc;

procedure kostprijs(o_min_dir_kostprijs_mnd out number
                   ,o_min_gewenst_tarief    out number) is

  cursor c_par is
    select salaris
    ,      grondslag_aftrek
    ,      pensioen_perc
    ,      wg_lasten
    ,      laptop_prijs
    ,      telefoon_prijs
    ,      telefoon_abo
    ,      omzet_perc
    ,      auto_leasekosten
    ,      auto_brandstofkosten
    ,      opleiding_budget
    ,      eerste_maand_berekening
    ,      laatste_maand_berekening
    from   ori_parameters
    where  usr_fk = (select id from ori_users where username = v('APP_USER'));
    r_par                      c_par%rowtype;

    l_bruto_jaarsalaris     number;
    l_pensioen_jr           number;
    l_wg_lasten_jr          number;
    l_comm_kosten           number;
    l_opleidingen           number;
    l_jaarkosten            number;
    l_autokosten            number;
    l_brandstofkosten       number;
    l_min_dir_kostprijs_jr  number;
    l_min_dir_kostprijs_mnd number;
    l_gewenste_dekking_jr   number;
    l_gewenste_dekking_mnd  number;
    l_min_gewenst_tarief    number;
    urencalc_row tr_standaard_urencalc;
begin
    open c_par;
    fetch c_par into r_par;
    close c_par;
    --
    standaard_urencalc(urencalc_row.min_charge_uren_jr
                      ,urencalc_row.min_charge_uren_mnd
                      ,urencalc_row.max_charge_uren_jr
                      ,urencalc_row.max_charge_uren_mnd);

    l_bruto_jaarsalaris     := r_par.salaris * 12.96;
    l_pensioen_jr           := ((l_bruto_jaarsalaris - r_par.grondslag_aftrek)/100) * r_par.pensioen_perc;
    l_wg_lasten_jr          := (l_bruto_jaarsalaris/100) * r_par.wg_lasten;
    l_comm_kosten           := (r_par.laptop_prijs/2) + (r_par.telefoon_prijs/2) + (r_par.telefoon_abo *12);
    l_opleidingen           := r_par.opleiding_budget;
    l_jaarkosten            := l_bruto_jaarsalaris + l_pensioen_jr + l_wg_lasten_jr + l_comm_kosten + l_opleidingen;
    l_autokosten            := r_par.auto_leasekosten * 12;
    l_brandstofkosten       := r_par.auto_brandstofkosten * 12;
    l_min_dir_kostprijs_jr  := l_jaarkosten + l_autokosten + l_brandstofkosten;
    l_min_dir_kostprijs_mnd := l_min_dir_kostprijs_jr / 12;
    l_gewenste_dekking_jr   := l_min_dir_kostprijs_jr + (l_min_dir_kostprijs_jr / r_par.omzet_perc) * r_par.omzet_perc;
    l_gewenste_dekking_mnd  := l_gewenste_dekking_jr / 12;
    l_min_gewenst_tarief    := l_min_dir_kostprijs_jr/12 * ((r_par.laatste_maand_berekening - r_par.eerste_maand_berekening)+1) / urencalc_row.min_charge_uren_jr;
    o_min_dir_kostprijs_mnd := l_min_dir_kostprijs_mnd/(r_par.omzet_perc/100);
    o_min_gewenst_tarief    := l_min_gewenst_tarief/(r_par.omzet_perc/100);
end kostprijs;

function fn_kostprijs return tt_kostprijs pipelined as
  kostprijs_row tr_kostprijs;
begin
  kostprijs(kostprijs_row.min_dir_kostprijs_mnd
           ,kostprijs_row.min_gewenst_tarief);
  pipe row (kostprijs_row);
  return;
end fn_kostprijs;

procedure bonuscalc is
begin
  null;

end bonuscalc;

procedure mass_book_hours (i_usr_id      in number
                          ,i_period      in varchar2
                          ,i_gebeurtenis in varchar2
                          ,i_uren        in number) is
  cursor c_date is
    select datum
    from (select trunc(to_date(i_period,'YYMM') + ROWNUM - 1) datum
          from dual connect by rownum < 32)
    where to_char(datum,'YYMM') = i_period
    and   to_char(datum,'dy') in ('mon','tue','wed','thu','fri');
begin
  for r_date in c_date
  loop
    update ori_kalenders
    set    gebeurtenis = i_gebeurtenis
    ,      uren        = i_uren
    where  usr_id      = i_usr_id
    and    datum = r_date.datum;
    if sql%rowcount = 0 then
      insert into ori_kalenders (gebeurtenis, uren, usr_id, datum)
      values (i_gebeurtenis, i_uren, i_usr_id, r_date.datum);
    end if;
  end loop;
end;

procedure test IS
BEGIN
  --This is a test procedure
  null;
end test;

end "ORI_CALC_PCK";