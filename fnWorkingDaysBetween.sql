drop table PublicHolidays CASCADE CONSTRAINTS;
create table PublicHolidays( 
    calday    date not null primary key,
    is_holiday      varchar2(1) default 'N',
    holiday_name    varchar2(50) null,
    region          varchar2(20) null,
  constraint calday_is_midnight check (calday=trunc(calday))
);


/*  Woring Days Calculation function JM 20220405
    Includes first and last days of given date range 
    To exclude the last day in range, append -1 to the EndDate input parameter in the function call.

    i.e
        select fnWorkingDaysBetween(
            to_date('01-04-2022','dd-MM-yyyy')
            , to_date('28-04-2022','dd-MM-yyyy') -1   -- this will exclude last day in range
            ,'UK' 
            ) as business_days 
            from dual;
 */
create or replace
FUNCTION fnWorkingDaysBetween (p_start_date IN DATE, p_end_date IN DATE, regions IN varchar2)
        RETURN NUMBER IS
        Hols     NUMBER;
        StartDate   DATE   := TRUNC (p_start_date);
        EndDate     DATE   := TRUNC (p_end_date);
        BEGIN
        IF EndDate >= StartDate
        THEN
                SELECT COUNT (*)
                INTO Hols
                FROM PublicHolidays PH
                WHERE calday BETWEEN StartDate AND EndDate
                AND calday NOT IN (
                        SELECT PH.calday 
                        FROM PublicHolidays PH 
                        WHERE MOD(TO_CHAR(PH.calday, 'J'), 7) + 1 IN (6, 7)
                        AND is_holiday='Y'
                        AND region in Regions
                );
        RETURN   GREATEST (NEXT_DAY (StartDate, 'MON') - StartDate - 2, 0)
             +   (  (  NEXT_DAY (EndDate, 'MON')
                     - NEXT_DAY (StartDate, 'MON')
                    )
                  / 7
                 )
               * 5
             - GREATEST (NEXT_DAY (EndDate, 'MON') - EndDate - 3, 0)
             - Hols;
        ELSE
                RETURN NULL;
        END IF;
END fnWorkingDaysBetween;
/


 select fnWorkingDaysBetween(
      to_date('01-01-2022','dd-MM-yyyy')
     , to_date('31-12-2022','dd-MM-yyyy')
     ,'UK'  
     ) as business_days 
    from dual;

    /*
    Results:
        
    BUSINESS_DAYS
    -------------
            260

    Matches: https://www.timeanddate.com/date/workdays.html?d1=01&m1=01&y1=2022&d2=31&m2=12&y2=2022&ti=on&
    */


/* insert UK public holidays */

insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('03-01-2022','dd-MM-yyyy'),'Y','New Year''s Day', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('15-04-2022','dd-MM-yyyy'),'Y','Good Friday', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('02-05-2022','dd-MM-yyyy'),'Y','Early Mayday Bank Holiday', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('02-06-2022','dd-MM-yyyy'),'Y','Spring Bank Holiday', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('03-06-2022','dd-MM-yyyy'),'Y','Queen''s Platinum Jubilee', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('16-12-2022','dd-MM-yyyy'),'Y','Boxing Day', 'UK');
insert into PublicHolidays (calday, is_holiday, holiday_name, region) values (to_date('27-12-2022','dd-MM-yyyy'),'Y','Substitute Bank Holiday for Christmas Day', 'UK');

commit;

 select fnWorkingDaysBetween(
      to_date('01-01-2022','dd-MM-yyyy')
     , to_date('31-12-2022','dd-MM-yyyy')
     ,'UK' 
     ) as business_days 
    from dual;

    /*
    Results:
        
    BUSINESS_DAYS
    -------------
            253

    Matches: https://www.timeanddate.com/date/workdays.html?d1=01&m1=01&y1=2022&d2=31&m2=12&y2=2022&ti=on&
    */


