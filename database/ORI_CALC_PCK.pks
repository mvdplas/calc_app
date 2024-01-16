create or replace package "ORI_CALC_PCK" as

type tr_standaard_urencalc is record
(min_charge_uren_jr   number
,min_charge_uren_mnd  number
,max_charge_uren_jr   number
,max_charge_uren_mnd  number);
--
type tt_standaard_urencalc is table of tr_standaard_urencalc;
--
type tr_kostprijs is record
(min_dir_kostprijs_mnd number
,min_gewenst_tarief    number);
--
type tt_kostprijs is table of tr_kostprijs;
--
procedure standaard_urencalc (o_min_charge_uren_jr  out number
                             ,o_min_charge_uren_mnd out number
                             ,o_max_charge_uren_jr  out number
                             ,o_max_charge_uren_mnd out number);
--
function fn_standaard_urencalc return tt_standaard_urencalc pipelined;
--
procedure kostprijs(o_min_dir_kostprijs_mnd out number
                   ,o_min_gewenst_tarief    out number);
--
function fn_kostprijs return tt_kostprijs pipelined;
--
procedure bonuscalc;

procedure mass_book_hours (i_usr_id      in number
                          ,i_period      in varchar2
                          ,i_gebeurtenis in varchar2
                          ,i_uren        in number);

end "ORI_CALC_PCK";