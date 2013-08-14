/*
program: cronrgf.cmd
type:    REXXSAA-OS/2, OS/2 2.x
purpose: Unix-like cron; allow to repeatedly execute commands at given date/time
         defined in a control file
version: 2.0.3
date:    1992-06-10
changed: 1993-03-19, bug fixed (caused no scheduling between 23:00 and 23:59),
                           logging added (so you can check for yourself)
         1993-11-05, added option to reread (/R) the cronfile at specified times (default every 60 minutes),
                           suggested by fmerrow@nyx10.cs.du.edu (Frank Merrow);
                     added option to execute all programs once since midnight (/M) and the time cronrgf was invoked,
                           suggested by sktoni@uta.fi (Tommi Nieminen);
                     added colorized output and option (/B) to use black and white
                           instead of ANSI-colors on output
         1993-11-22, added ability to look for cronfile in the directory in which cronrgf.cmd is stored,
                           if no path was explicitly given; hence one can start cronrgf.cmd from
                           any drive/directory without the need to specify a full path for the cronfile
         1994-04-04, changed the way the log-file is handled (will be closed after it was written to, hence one can
                           delete the log-file after a certain while, if one feels it has become too large)
         1996-04-30, changed testing of valid date from flag "M" to "C", in order to prohibit an error message,
                           if an illegal date was produced (needs datergf.cmd version 1.6 for this to be true)
         1997-05-03, changed a bug in the dispatch-loop (thanks to <Del_Brown@afcc.fabrik.com> !)

author:  Rony G. Flatscher
         Rony.Flatscher@wu-wien.ac.at

needs:   DATERGF.CMD, SCRCOLOR.CMD, some RxFuncts (loaded automatically)

usage:   CRONRGF [/T] [/M] [/R[nn]] [/B] cronfile


    Reads file 'cronfile' and executes command[s] repeatedly according to it.
    'cronfile' has to be formatted like in Unix; unlike the Unix-version a '%' is
    treated like any other character; empty lines and ones starting with
    a semi-colon (;) or a (#) are ignored.

    Switch '/T[estmode]': the cronfile is read and the user is presented with the date/times
          and commands to be executed upon them. The planned and truly scheduled
          times are written to the log-file.

    Switch '/M[idnight]': all commands which were scheduled the same day, starting from
          midnight to the time of first invocation are executed once.

    Switch '/R[nn]': check cronfile at least every 'nn' (default 60) minutes whether it changed; if so, reread
          it immediately and set the new schedule-times. If set, the cronfile will be checked for changes after
          executing commands

    Switch '/B[lackAndWhite]': do not colorize output strings (e.g. for usage in more, less etc.).
          This switch merely suppresses the ANSI-color-sequences attached to the
          strings.

    example:  CRONRGF /TEST testcron
              execute statements in file 'testcron' in testmode

    example for a control-file:

        ; Sample file for CRONRGF.CMD
        ;
        ; This is a comment (starts with a semicolumn)
        # This is a comment too (starts with the Unix-comment symbol)
        ; empty lines are ignored too...


        ; LAYOUT OF THE CRON-FILE:
        ;    * * * * * command
        ; or
        ;    minute hour day month weekday command
        ; where minute  ranges from 0-59,
        ;       hour    ranges from 0-23,
        ;       day     ranges from 1-31,
        ;       month   ranges from 1-12,
        ;       weekday ranges from 1-7 (1 = Monday, 2 = Tuesday, ..., 7 = Sunday)
        ;
        ; you can give a list of values, separated by a comma (,), e.g. "1,3,7"
        ; you can give a range of values, separated by a dash (-), e.g. "1-5"
        ; you can give a star (*) instead of a value, meaning entire range of all valid values
        ;
        ; the given command is only executed when all criteriae are fullfilled !
        ;
        ; restriction: unlike to Unix, the percent-sign (%) is treated like any other character and
        ;              not as a new-line
        ;

        # the following command "@ECHO HI, I am Nr. 1 to be echoed every minute" would be
        # executed every minute
        *  *  *  *  *  @ECHO Hi, I am Nr. 1 to be echoed every minute & pause

        59 23 31 12 5 command, one minute before year's end, and only if the last day is a Friday

        ; comment: every year at 17:45 on June 7th:
        45 17  7  6  *  dir c:\*.exe

        ; comment: on every full quarter of an hour
        ;          at midnight, 6 in the morning, noon, 6 in the evening
        ;          on the 1st, 15th and 31st of
        ;          every month on
        0,15,30,45   0,6,12,18   1,15,31   *   *   backup c:\*.* d:\ /s

        ; at noon on every day, if it is a weekday (Mo-Fri):
        0 12 * * 1-5 XCOPY Q:\* D:\ /s

        ; every minute in January, March, May, July, September and November:
        *  *  *  1,3,5,7,9,11  *  dir c:\*.cmd

        # at the last day of the year at 23:01, 23:02, 23:03, 23:05, 23:20, 23:21,
        # 23:22, 23:23, 23:24, 23:25, 23:30, 23:31, 23:32, 23:33, 23:34, 23:35,
        # 23:59
        1,2,3,5,20-25,30-35,59   23   31   12   *   COPY D:\*.log E:\backup

        ; make backups of OS2.INI and OS2SYS.INI on every first monday of a month,
        ; at 9 o'clock in the morning
        0 9 1-7 * 1 showini /bt d:\os2\os2.ini
        0 9 1-7 * 1 showini /bt d:\os2\os2sys.ini

        ; at midnight on every month:
        0 0 1 * * tapebackup /all

        ; execute every minute, no restrictions:
        *  *  *  *  *  @ECHO Hi, I am Nr. 2 to be echoed every minute & pause

        # execute every minute in January, February, March only !
        * *  *  1,2,3  *  any-command any-arguments

        # execute every day at midnight
        0 0 * * * any-command any-arguments

        # execute every wednesday at midnigth !
        0 0 * * 3 any-command any-arguments

        # this is a comment which concludes the sample file ===========================

All rights reserved, copyrighted 1992, no guarantee that it works without
errors, etc. etc.

donated to the public domain granted that you are not charging anything (money
etc.) for it and derivates based upon it, as you did not write it,
etc. if that holds you may bundle it with commercial programs too

you may freely distribute this program, granted that no changes are made
to it

Please, if you find an error, post me a message describing it, I will
try to fix and rerelease it to the net.

*/
SIGNAL ON HALT
SIGNAL ON ERROR
SIGNAL ON FAILURE    NAME ERROR
SIGNAL ON NOTREADY   NAME ERROR
SIGNAL ON NOVALUE    NAME ERROR
SIGNAL ON SYNTAX     NAME ERROR

global. = ""                    /* default for global */
global.eTestmode = "0"          /* default: no testmode */
global.eFirstInvocation = 0     /* don't execute commands since midnight up to invocation time */
global.eCheckCronFile = 0       /* don't check whether cronfile was changed */

stemSchedule. = ""      /* default for empty array elements */

pos = POS("/B", TRANSLATE(ARG(1)))

IF pos > 0 THEN         /* no screen-colors */
DO
   arg_1 = SUBSTR(ARG(1), 1, pos-1)

   /* ignore characters up to next blank or slash */
   DO i = pos + 1 TO LENGTH(ARG(1))
      IF VERIFY(SUBSTR(ARG(1), i, 1), "/ ") = 0 THEN LEAVE
   END

   arg_1 = arg_1 || SUBSTR(ARG(1), i)
END
ELSE
DO
   /* get screen-colors */
   PARSE VALUE ScrColor() WITH global.eScrNorm    global.eScrInv,
                               global.eTxtNorm    global.eTxtInf,
                               global.eTxtHi      global.eTxtAla,
                               global.eTxtNormInv global.eTxtInfInv,
                               global.eTxtHiInv   global.eTxtAlaInv .
   arg_1 = ARG(1)
END

IF arg_1 = "" THEN SIGNAL usage

/* three arguments ? */
PARSE VAR arg_1 "/"switch1 "/"switch2 "/"switch3 filein

IF filein = "" THEN
   PARSE VAR arg_1 filein "/"switch1 "/"switch2 "/"switch3


/* two arguments ? */
IF filein = "" THEN
   PARSE VAR arg_1 "/"switch1 "/"switch2 filein

IF filein = "" THEN
   PARSE VAR arg_1 filein "/"switch1 "/"switch2


/* one argument ? */
IF filein = "" THEN
   PARSE VAR arg_1 "/"switch1 filein

IF filein = "" THEN
   PARSE VAR arg_1 filein "/"switch1


/* no argument */
IF filein = "" THEN
   PARSE VAR arg_1 filein                 /* get filename */

IF filein = "" | filein = "?" THEN
   SIGNAL usage

switches = TRANSLATE(LEFT(switch1, 1) || LEFT(switch2, 1) || LEFT(switch3, 1))

/* check whether switches are valid */
IF VERIFY(switches, "TMR ") <> 0 THEN
DO
   CALL say_c global.eTxtAla || "CRONRGF: unknown switch in [" || global.eTxtHi || arg_1 || global.eTxtAla || "]."
   CALL say_c
   CALL BEEP 2500, 100
   SIGNAL usage              /* wrong switch */
END

switch_text = ""

IF POS("T", switches) > 0 THEN
DO
   global.eTestmode = "1"
   switch_text = switch_text "/T"
END

IF POS("M", switches) > 0 THEN
DO
   global.eFirstInvocation = 1
   switch_text = switch_text "/M"
END

IF POS("R", switches) > 0 THEN
DO
   pos = POS("R", switches)
   SELECT
      WHEN pos = 1 THEN tmp = switch1
      WHEN pos = 2 THEN tmp = switch2
      OTHERWISE tmp = switch3
   END

   PARSE UPPER VAR tmp "R" minutes

   IF minutes = "" THEN minutes = 60    /* default to 60 minutes */
   ELSE IF \DATATYPE(minutes, "N") | minutes < 5 | minutes > 43200 THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: wrong minute-value in switch [/" || global.eTxtHi || tmp || global.eTxtAla || "]."
      CALL say_c  global.eTxtAla || "         (valid range 5-43200 minutes = 5 minutes to 30 days)."
      CALL say_c
      CALL BEEP 2500, 100
      SIGNAL usage              /* wrong switch */
   END
   switch_text = switch_text "/R" || minutes
   global.eMinutesToSleep = minutes
   global.eSecondsToSleep = minutes * 60
   global.eCheckCronFile = 1
END

/* construct name of LOG-file */
PARSE SOURCE . . full_path_of_this_procedure
global.eLogFile = SUBSTR(full_path_of_this_procedure, 1,,
                         LASTPOS(".", full_path_of_this_procedure)) || "LOG"

filein = STRIP(filein)          /* get rid of leading and trailing spaces */
global.eFilein = STREAM(filein, "C", "QUERY EXISTS")

IF global.eFilein = "" THEN
DO
   /* supply drive & path of cronrgf.cmd, if cronfile does not have any */
   IF FILESPEC("Drive", filein) = "" & FILESPEC("Path", filein) = "" THEN
   DO
      PARSE SOURCE . . this
      filein = FILESPEC("Drive", this) || FILESPEC("Path", this) || filein
      global.eFilein = STREAM(filein, "C", "QUERY EXISTS")
   END

   IF global.eFilein = "" THEN          /* still no cronfile ? */
      CALL stop_it "cronfile [" || filein || "] does not exist."
END

/* check whether RxFuncs are loaded, if not, load them */
IF RxFuncQuery('SysLoadFuncs') THEN
DO
    /* load the load-function */
    CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'

    /* load the Sys* utilities */
    CALL SysLoadFuncs
END

CALL WRITE_LOG LEFT("", 80, "-")
CALL WRITE_LOG "(Logging-session started:" date("S") time() || ")"
CALL WRITE_LOG "  (Switches in effect) [" || STRIP(switch_text) || "]"

CALL read_cronfile     /* read given CRON-file */

IF global.0 > 0 THEN
   CALL dispatch                                /* start dispatching */

CALL stop_it "Nothing to schedule. Program ended."




/*
        FOREVER-LOOP
*/
DISPATCH: PROCEDURE EXPOSE global. stemSchedule.

   IF global.eCheckCronFile THEN
      sleeping_time = global.eSecondsToSleep
   ELSE                        /* take care of DosSleep()-unsigned long; to be safe just sleep a maximum */
      sleeping_time = 2678400  /* of 31 days (= 31 * 24 * 60 * 60  == 2.678.400 seconds) at a time       */



   DO forever_loop = 1 TO 5
      forever_loop = 1          /* don't let the forever-loop expire */
      CALL say_c RIGHT("", 79, "=")
      CALL say_c
      CALL say_c "Scheduling commands given in cronfile:"      /* show user which file is being used */
      CALL say_c

      CALL say_c "  [" || global.eTxtHi || global.eFilein || global.eTxtInf || "]"

      IF global.eCheckCronFile THEN
         CALL say_c "  (being checked after executing commands, at least every"  global.eTxtHi || global.eMinutesToSleep  global.eTxtInf || "minutes)"

      IF global.eFirstInvocation THEN
         CALL say_c "  (executing once all commands between midnight and now, switch:" global.eTxtHi ||  "/M" || global.eTxtInf || ")"

      CALL say_c

      CALL schedule_next
      /* show user which command(s) will be executed when */
      PARSE VAR stemSchedule.1 1 next_date_time 18      /* get next date/time */

      /* get actual DATE/TIME */
      act_date_time = DATE("S") TIME()

      IF global.eTestmode THEN
      DO
         IF \global.eFirstInvocation THEN
             act_date_time = next_date_time

         CALL say_c "command[s] being scheduled on:"  global.eTxtHi || act_date_time
      END
      ELSE
         CALL say_c "command[s] being scheduled on:"  global.eTxtHi || next_date_time

      CALL say_c

      DO i = 1 TO stemSchedule.0
         PARSE VAR stemSchedule.i 1 tmp_date_time 18 status index

         IF tmp_date_time > next_date_time THEN LEAVE

         IF status = "OK" THEN
         DO
            CALL say_c "  [" || global.eTxtHi || VALUE("global." || index || ".eCommand.eValues") || global.eTxtInf || "]"
            IF global.eTestmode THEN           /* write info to LOG-File */
            DO
               CALL WRITE_LOG "  (Testmode)" act_date_time "(scheduled for" next_date_time ||,
                                             ") [" || VALUE("global." || index || ".eCommand.eValues") || "]"
            END
         END
      END
      CALL say_c

      /* get actual DATE/TIME */
      difference = DATERGF(next_date_time, "-S", act_date_time)

      IF difference > 0 THEN seconds_to_sleep = DATERGF(difference, "SEC") % 1
                        ELSE seconds_to_sleep = 0

      IF global.eTestmode THEN
      DO
         IF \global.eFirstInvocation THEN
            act_date_time = next_date_time

         CALL say_c RIGHT("", 79, "=")
         CALL say_c "Testmode (dispatch):    next_invocation ="  global.eTxtHi || next_date_time
         CALL say_c "Testmode (dispatch):   actual date/time ="  global.eTxtHi || act_date_time
         IF difference < 0 THEN
            CALL say_c "Testmode (dispatch):                     " global.eTxtHi || "Immediate !"
         ELSE
            CALL say_c "Testmode (dispatch): difference in days =" global.eTxtHi || difference,
                       global.eTxtInf || "=" global.eTxtHi || seconds_to_sleep  global.eTxtInf || "seconds"

         CALL say_c RIGHT("", 79, "=")

         CALL say_c "Testmode (dispatch):"
         CALL say_c "   input:"
         DO i = 1 TO global.0
            CALL say_c "     [" || global.eTxtHi || RIGHT(i, LENGTH(global.0)) || global.eTxtInf || "]" global.original.i
         END
         CALL say_c RIGHT("", 79, "=")

         CALL say_c "   schedule list:"
         DO i = 1 TO stemSchedule.0
            PARSE VAR stemSchedule.i . . . gIndex
            CALL say_c "    " stemSchedule.i "[" || global.eTxtHi || VALUE("global." || gIndex || ".eCommand.eValues") || global.eTxtInf || "]"
         END
         CALL say_c RIGHT("", 79, "=")

         CALL say_c 'Press any key to continue, "q" to quit.'
         CALL BEEP 500, 100
         IF TRANSLATE(SysGetKey("NOECHO")) = "Q" THEN SIGNAL halt
      END
      ELSE
      DO
         DO WHILE seconds_to_sleep > 0
            sleeping         = MIN(seconds_to_sleep, sleeping_time)
            seconds_to_sleep = MAX(0, seconds_to_sleep - sleeping_time)

            CALL SysSleep sleeping                      /* sleep */

            /* update sleeping-time, get actual DATE/TIME */
            difference = DATERGF(next_date_time, "-S", DATE("S") TIME())

            IF difference > 0 THEN seconds_to_sleep = DATERGF(difference, "SEC") % 1
                              ELSE seconds_to_sleep = 0

            /* if cronfile should be checked and another sleeping-turn is coming up, then reread the cronfile */
            IF global.eCheckCronFile & seconds_to_sleep > 0 THEN
            DO
               IF cronfile_changed() THEN
               DO
                  CALL do_the_cronfile_reread
                  ITERATE forever_loop        /* reschedule */
               END
            END
         END

         act_date_time = DATE("S") TIME()       /* now get the up-to-date time, was bug pointed to by Del Brown */

         DO i = 1 TO stemSchedule.0
           PARSE VAR stemSchedule.i 1 date_time 18 status index
           IF date_time > act_date_time THEN LEAVE

           IF status = "OK" THEN
           DO
              /*
                 start an own minimized session which closes automatically after the
                 command was executed:
              */
              commandString = VALUE('global.' || index || '.eCommand.eValues')
              title = '"CRONRGF:' date_time STRIP(commandString) '"'
              ADDRESS CMD "@START" title '/C /WIN /MIN /B "' || commandString || '"'

              CALL WRITE_LOG "(dispatched)" date("S") time() "(scheduled for" date_time || ") [" || commandString || "]"
           END
         END
      END

      global.eFirstInvocation = 0 /* programs from midnight up to invocation time were executed, stop that behavior */

      /* reread cronfile, if set and if cronfile changed or in testmode */
      IF global.eCheckCronFile & (cronfile_changed() | global.eTestmode) THEN
      DO
         CALL do_the_cronfile_reread
         ITERATE forever_loop        /* reschedule */
      END


      /* change the status of the executed programs to "NOK" */
      DO i = 1 TO stemSchedule.0
         PARSE VAR stemSchedule.i 1 date_time 18 status index

         IF date_time > act_date_time THEN LEAVE

         stemSchedule.i = act_date_time "NOK" index
      END

   END

   RETURN



/*
    calculate the schedule times, sort them in ascending order
*/
SCHEDULE_NEXT: PROCEDURE EXPOSE global. stemSchedule.
   /*
      as long as no viable date/time to schedule was found, iterate
   */
   main_run = 0
   DO WHILE WORD(stemSchedule.1, 3) <> "OK"
      main_run = main_run + 1                           /* count loops until a valid day was found for any of the commands */

      IF global.eTestmode THEN
         CALL say_c "Testmode (scheduling): main loop ="  global.eTxtHi || main_run

      IF main_run > 50 THEN
      DO
         CALL stop_it "SCHEDULE_NEXT(): aborting after 50 attempts to produce a valid date!"
      END

      DO i = 1 TO stemSchedule.0
         PARSE VAR stemSchedule.i 1 year 5 month 7 day 9 10 hour 12 13 minute 15 18 disp_status glob_index

         IF disp_status = "OK" THEN ITERATE             /* not yed scheduled */
         old_year  = year
         old_month = month
         old_day   = day
         old_hour  = hour

         /* defaults */
         first_minute = WORD(global.glob_index.eMinute.eValues, 1)
         first_hour   = WORD(global.glob_index.eHOur.eValues, 1)
         first_day    = WORD(global.glob_index.eDay.eValues, 1)
         first_month  = WORD(global.glob_index.eMonth.eValues, 1)


         /* minute */
         DO j = 1 TO global.glob_index.eMinute.0
            tmp = WORD(global.glob_index.eMinute.eValues, j)
            IF tmp > minute THEN LEAVE
         END

         IF j > global.glob_index.eMinute.0 THEN        /* minutes to wrap around */
            hour   = hour + 1
         ELSE                                           /* minutes within same hour */
            minute = tmp

         /* hour */
         DO j = 1 TO global.glob_index.eHour.0
            tmp = WORD(global.glob_index.eHour.eValues, j)
            IF tmp >= hour THEN LEAVE
         END
         IF j > global.glob_index.eHour.0 THEN          /* hours to wrap around */
            day    = day + 1
         ELSE                                           /* hours within same day */
            hour   = tmp

         ok = "NOK"                                     /* default: no date found yet */
         run = 0
         DO 50                                          /* try 50 times to produce a valid date */
            run = run + 1
            /* day */
            DO j = 1 TO global.glob_index.eDay.0
               tmp = WORD(global.glob_index.eDay.eValues, j)
               IF tmp >= day THEN LEAVE
            END

            IF j > global.glob_index.eDay.0 THEN        /* days to wrap around */
            DO
               day    = first_day
               month  = month + 1
            END
            ELSE                                        /* days within same month */
               day    = tmp


            /* month */
            DO j = 1 TO global.glob_index.eMonth.0
               tmp = WORD(global.glob_index.eMonth.eValues, j)
               IF tmp >= month THEN LEAVE
            END

            IF j > global.glob_index.eMonth.0 THEN      /* months to wrap around */
            DO
               day    = first_day
               month  = first_month
               year   = year + 1
            END
            ELSE                                        /* months within same year */
            DO
               IF month <> tmp THEN                     /* did the month change ? */
                  day = first_day

               month  = tmp
            END


            SELECT
               WHEN old_year < year | old_month < month | old_day < day THEN
                    next_invocation = year || month || day first_hour || ":" || first_minute || ":00"
               WHEN old_hour < hour THEN
                    next_invocation = year || month || day       hour || ":" || first_minute || ":00"
               OTHERWISE
                    next_invocation = year || month || day       hour || ":" ||       minute || ":00"
            END

            IF global.eTestmode THEN
               CALL say_c "Testmode (scheduling): next_invocation ="  global.eTxtHi || next_invocation DATERGF(next_invocation, "DN")

            /* check whether day-of-week is o.k. */
            IF DATERGF(next_invocation, "C") = "" THEN  /* illegal date produced, e.g. 19950231 ? */
            DO
               day   = first_day
               month = month + 1
               IF month > 12 THEN
               DO
                 month = first_month
                 year  = year + 1
               END
               ITERATE
            END


            next_Weekday = DATERGF(next_invocation, "DI")  /* get weekday */

            /* using POS because weekdays are in the form of 01, 02, ..., 07 */
            IF POS(next_Weekday, global.glob_index.eWeekday.eValues) = 0 THEN      /* invalid weekday ? */
            DO
               next_invocation = DATERGF(next_invocation, "+", "1")     /* add one day to present date */
               PARSE VAR next_invocation 1 year 5 month 7 day 9

               ITERATE
            END

            ok = " OK"                                  /* o.k. to invoke, because valid date */
            LEAVE
         END

         IF global.eTestmode THEN
         DO
            CALL say_c "Testmode (scheduling): date/time-loop ="  global.eTxtHi || run  global.eTxtInf || "time[s]"
            CALL say_c
         END


         /*
            format in schedule list:
            DATE TIME STATUS INDEX-INTO-GLOBAL-ARRAY
         */
         stemSchedule.i = next_invocation ok glob_index
      END

      CALL sort_schedule_list
   END

   RETURN

/*
    sort the schedule list in ascending order
*/
SORT_SCHEDULE_LIST: PROCEDURE EXPOSE global. stemSchedule.
   length = 21          /* length of SUBSTR to compare, includes status */
   /* define M for passes */
   M = 1
   DO WHILE (9 * M + 4) < stemSchedule.0
      M = M * 3 + 1
   END

   /* sort stem */
   DO WHILE M > 0
      K = stemSchedule.0 - M
      DO J = 1 TO K
         Q = J
         DO WHILE Q > 0
            L = Q + M
            IF SUBSTR(stemSchedule.Q, 1, length) <= SUBSTR(stemSchedule.L, 1, length) THEN LEAVE
            /* switch elements */
            tmp            = stemSchedule.Q
            stemSchedule.Q = stemSchedule.L
            stemSchedule.L = tmp
            Q = Q - M
         END
      END
      M = M % 3
   END

   RETURN





/*
   analyze

*/

CHECK_IT_OUT: PROCEDURE EXPOSE global. stemSchedule.

to_parse = ARG(1)
line_no  = ARG(2)

PARSE VAR to_parse sMinute sHour sDay sMonth sWeekday sCommand

line_no = setup_minutes(sMinute, line_no)       /* setup minute-values */

IF line_no <> 0 THEN                            /* setup hour-values */
   line_no = setup_hours(sHour, line_no)

IF line_no <> 0 THEN                            /* setup day-values */
   line_no = setup_days(sDay, line_no)

IF line_no <> 0 THEN                            /* setup month-values */
   line_no = setup_months(sMonth, line_no)

IF line_no <> 0 THEN                            /* setup weekday-values */
   line_no = setup_weekdays(sWeekday, line_no)

IF line_no <> 0 THEN                            /* setup command-values */
DO
   global.line_no.eCommand.0       = 1
   global.line_no.eCommand.eValues = sCommand
END

RETURN line_no

/*
        parse and setup minutes
        ARG(1) - minute string
        ARG(2) - index into global array
*/
SETUP_MINUTES: PROCEDURE EXPOSE global. stemSchedule.
   sMinute = ARG(1)
   iIndex = ARG(2)
   default.0 = 60
   default.values = "00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39",
                    "40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59"

   string = parse_it("eMinute", sMinute, iIndex, 0, 59, default.0, default.values)

   IF string <> "" THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: error in minute-format" global.eTxtHi || "[" || string || "]"
      CALL say_c
      RETURN 0
   END

   RETURN iIndex



/*
        parse and setup hours
        ARG(1) - hour string
        ARG(2) - index into global array
*/
SETUP_HOURS: PROCEDURE EXPOSE global. stemSchedule.
   sHour = ARG(1)
   iIndex = ARG(2)
   default.0 = 24
   default.values = "00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23"

   string = parse_it("eHour", sHour, iIndex, 0, 23, default.0, default.values)

   IF string <> "" THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: error in hour-format" global.eTxtHi || "[" || string || "]"
      CALL say_c
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup days
        ARG(1) - day string
        ARG(2) - index into global array
*/
SETUP_DAYS: PROCEDURE EXPOSE global. stemSchedule.
   sDay = ARG(1)
   iIndex = ARG(2)
   default.0 = 31
   default.values = "   01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19",
                    "20 21 22 23 24 25 26 27 28 29 30 31"

   string = parse_it("eDay", sDay, iIndex, 1, 31, default.0, default.values)

   IF string <> "" THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: error in day-format" global.eTxtHi || "[" || string || "]"
      CALL say_c
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup months
        ARG(1) - month string
        ARG(2) - index into global array
*/
SETUP_MONTHS: PROCEDURE EXPOSE global. stemSchedule.
   sMonth = ARG(1)
   iIndex = ARG(2)
   default.0 = 12
   default.values = "01 02 03 04 05 06 07 08 09 10 11 12"

   string = parse_it("eMonth", sMonth, iIndex, 1, 12, default.0, default.values)

   IF string <> "" THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: error in month-format" global.eTxtHi || "[" || string || "]"
      CALL say_c
      RETURN 0
   END

   RETURN iIndex




/*
        parse and setup weekdays
        ARG(1) - weekday string
        ARG(2) - index into global array
*/
SETUP_WEEKDAYS: PROCEDURE EXPOSE global. stemSchedule.
   sWeekday = ARG(1)
   iIndex = ARG(2)
   default.0 = 7
   default.values = "01 02 03 04 05 06 07"

   string = parse_it("eWeekday", sWeekday, iIndex, 1, 7, default.0, default.values)

   IF string <> "" THEN
   DO
      CALL say_c  global.eTxtAla || "CRONRGF: error in weekday-format" global.eTxtHi || "[" || string || "]"
      CALL say_c
      RETURN 0
   END

   RETURN iIndex







/*
        parse values, list, setup array
        ARG(1) = eName ("element name" in array)
        ARG(2) = string containing numbers
        ARG(3) = index into global array
        ARG(4) = lower bound (inclusive)
        ARG(5) = upper bound (inclusive)
        ARG(6) = default number of elements
        ARG(7) = default values
*/

PARSE_IT: PROCEDURE EXPOSE global. stemSchedule.
   eName       = ARG(1)
   sValues        = ARG(2)
   iIndex         = ARG(3)
   lower          = ARG(4)
   upper          = ARG(5)
   default.0      = ARG(6)
   default.values = ARG(7)


   tmp = "global.iIndex." || eName || "."            /* build string of array-e-Name */
   lastValue = 0

   IF sValues = "*" THEN                /* build all legal values */
   DO
      INTERPRET(tmp || "0 =" default.0)
      INTERPRET(tmp || "eValues =" default.values)
      RETURN ""
   END

   INTERPRET(tmp || "0 = 0")                            /* set number of elements to 0 */
   INTERPRET(tmp || 'eValues = ""')                     /* delete values */

   DO WHILE sValues <> ""
      IF POS(",", sValues) > 0 THEN                     /* list of values ? */
        PARSE VAR sValues tmpValue "," sValues
      ELSE
      DO
        tmpValue = sValues
        sValues = ""
      END

      IF POS("-", tmpValue) > 0 THEN                    /* range of values ? */
      DO
         PARSE VAR tmpValue start "-" end
      END
      ELSE                                              /* single value */
      DO
         start = tmpValue
         end   = tmpValue
      END



      /* error in values ? */
      IF start < lastValue | start < lower | start > end | ,
         end > upper | ,
         \DATATYPE(start, "N") | \DATATYPE(end, "N") THEN
      DO
         INTERPRET(tmp || '0  = ""')                    /* delete number of array elements */
         INTERPRET(tmp || 'eValues = ""')               /* delete values */
         SELECT
            WHEN \DATATYPE(start, "N") THEN err_msg = '"' || start || '"' "is not numeric" '(part in error: "' || tmpValue || '")'
            WHEN \DATATYPE(end,   "N") THEN err_msg = '"' || end || '"' "is not numeric" '(part in error: "' || tmpValue || '")'
            WHEN start < lastValue     THEN err_msg = start "<" lastValue "= lower bound"  '(part in error: "' || tmpValue || '")'
            WHEN start < lower         THEN err_msg = start "<" lower "= lower bound"      '(part in error: "' || tmpValue || '")'
            WHEN start > end           THEN err_msg = start ">" end                        '(part in error: "' || tmpValue || '")'
            WHEN end   > upper         THEN err_msg = end   ">" upper "= upper bound"      '(part in error: "' || tmpValue || '")'
            OTHERWISE NOP
         END

         RETURN err_msg
      END

      /* build values */
      DO i = start TO end
         INTERPRET(tmp || "0 = " || tmp || "0 + 1")     /* increase counter for number of elements */
         INTERPRET(tmp || "eValues = " || tmp || "eValues" RIGHT(i, 2, "0"))   /* add the next value */
      END

      lastValue = i
   END

   RETURN ""



/*
   control-routine for rereading cronfile
*/
DO_THE_CRONFILE_REREAD: PROCEDURE EXPOSE global. stemSchedule.
   CALL say_c
   CALL say_c "CRONRGF: cronfile [" || global.eTxtHi || global.eFilein || global.eTxtInf || "] changed, rereading ..."

   IF global.eTestmode THEN
      tmp_leadin = "  (Testmode)"
   ELSE
      tmp_leadin = "            "

   CALL WRITE_LOG tmp_leadin date("S") time() "cronfile [" || global.eFilein || "] changed, rereading ..."

   CALL read_cronfile          /* read new cronfile */

   IF global.0 = 0 THEN        /* no valid entries found */
      CALL stop_it "cronfile [" || global.eFilein || "] not a cronfile anymore ! Aborting ..."

   RETURN



/*
   Read contents of CRON-file
*/

READ_CRONFILE: PROCEDURE EXPOSE global. stemSchedule.
   DROP stemSchedule.
   stemSchedule. = ""   /* default for empty array-elements */
   iSchedule = 0        /* schedule counter */
   line_no = 1          /* line-number */

   IF global.eFirstInvocation THEN      /* execute once from midnight to now */
      date_time = DATERGF(DATE("S"), "-", DATERGF("1", "SECR")) /* Subtract 1 second from 00:00am */
   ELSE
      date_time = DATE("S") TIME()

   CALL SysFileTree global.eFilein, "aTmp", "F"
   IF aTmp.0 <> 1 THEN
   DO
      CALL stop_it "control-file [" || global.eFilein || "] does not exist anymore !"
   END
   global.eFilein.eState = aTmp.1       /* assign present value of control-file */

   global.0 = 0
   DROP stemSchedule.
   stemSchedule. = ""

   DO WHILE LINES(global.eFilein) > 0
      line = LINEIN(global.eFilein)

      /* no empty lines and no comments */
      tmp = LEFT(STRIP(line), 1)
      IF line = "" | tmp = ";" | tmp = "#" THEN ITERATE

      CALL say_c "parsing ["  global.eTxtInf || line || global.eTxtInf || "]"

      IF check_it_out(line, line_no) > 0 THEN
      DO
         iSchedule = iSchedule + 1
         global.original.line_no = line
         stemSchedule.iSchedule =  date_time "NOK" line_no  /* NOK = not o.k., get next date/time */
         line_no = line_no + 1
      END
   END
   CALL say_c

   CALL WRITE_LOG"  (cronfile)" date("S") time() "[" || STRIP(global.eFilein.eState) || "]"

   global.eOriginal.0 = line_no - 1     /* original number of lines */
   global.0 = iSchedule                 /* set number of array elements */
   stemSchedule.0 = iSchedule           /* set number of array elements */
   CALL STREAM global.eFilein, "C", "CLOSE"     /* make sure, file is closed */

   RETURN



/*
   check, whether control-file changed
*/
CRONFILE_CHANGED: PROCEDURE EXPOSE global. stemSchedule.
   CALL SysFileTree global.eFilein, "aTmp", "F"
   IF aTmp.0 <> 1 THEN
   DO
      CALL stop_it "cronfile [" || global.eFilein || "] does not exist anymore ! Aborting ..."
   END

   RETURN global.eFilein.eState <> aTmp.1



/*
   User pressed ctl-c or closed session
*/
HALT:
   CALL STOP_IT "User interrupted program."

/*
   Clean up and close open files
*/
STOP_IT:
   IF global.eLogFile <> "" THEN
   DO
      IF ARG(1) <> "" THEN
         CALL WRITE_LOG "  (***ERROR:" date("S") time() "-"  ARG(1) || ")"

      CALL WRITE_LOG "(Logging-session ended:" date("S") time() || ")"
      IF LEFT(STREAM(global.eLogFile), 1) = "R" THEN
         CALL STREAM global.eLogFile, "C", "CLOSE"    /* close log-file */
   END

   IF ARG(1) <> "" THEN CALL say_c  global.eTxtAla || "CRONRGF:"  global.eTxtAlaInv || ARG(1)

   IF global.eFilein <> "" THEN
      IF LEFT(STREAM(global.eFilein), 1) = "R" THEN
         tmp = STREAM(global.eFilein, "C", "CLOSE")    /* make sure, file is closed */

   EXIT -1



USAGE:
   CALL say_c  global.eTxtHi || "CRONRGF.CMD"  global.eTxtInf || "- Unix-like cron; executes commands in file repeatedly."
   CALL say_c
   CALL say_c "usage:"
   CALL say_c
   CALL say_c  global.eTxtHi || "      CRONRGF [/T] [/M] [/R[nn]] [/B] cronfile"
   CALL say_c
   CALL say_c "Reads file '" || global.eTxtHi || "cronfile" || global.eTxtInf || "' and executes command[s] repeatedly according to it."
   CALL say_c "'cronfile' has to be formatted like in Unix; unlike the Unix-version a '%' is"
   CALL say_c "treated like any other character; empty lines and ones starting with"
   CALL say_c "a semi-colon (;) or with '#' are ignored."
   CALL say_c
   CALL say_c "Switch '" || global.eTxtHi || "/T" || global.eTxtInf || "': the cronfile is read and the user is presented with the date/times"
   CALL say_c "       and commands to be executed upon them."
   CALL say_c "Switch '" || global.eTxtHi || "/M" || global.eTxtInf || "': execute once the programs which would have been scheduled"
   CALL say_c "       between midnight and time of invocation."
   CALL say_c "Switch '" || global.eTxtHi || "/R[nn]" || global.eTxtInf || "': check cronfile at least every 'nn' (default 60) minutes"
   CALL say_c "       whether it changed; if so, reread it immediately and set the new"
   CALL say_c "       schedule-times. If given, the cronfile will be checked after dispatching"
   CALL say_c "       commands. If not given, cronfile will be read only once."
   CALL say_c "Switch '" || global.eTxtHi || "/B" || global.eTxtInf || "': do not colorize output strings (e.g. for usage in more, less"
   CALL say_c "       etc.). This switch merely suppresses the ANSI-color-sequences attached"
   CALL say_c "       to the strings (hence BlackAndWhite)."
   CALL say_c
   CALL say_c "examples:" global.eTxtHi || "CRONRGF /T crontest"
   CALL say_c "          .. execute statements in file 'crontest' in testmode"
   CALL say_c  global.eTxtHi || "          CRONRGF /T /M /R30 cronfile"
   CALL say_c "          .. execute statements in file 'cronfile' in testmode, schedule"
   CALL say_c "             programs which would have been started since midnight and time"
   CALL say_c "             of invocation, reread 'cronfile' at least every 30 minutes."
   CALL say_c  global.eTxtHi || "          CRONRGF /M /R some_file"
   CALL say_c "          .. execute statements in file 'some_file', schedule programs which"
   CALL say_c "             would have been started since midnight and time of invocation,"
   CALL say_c "             reread 'some_file' at least every 60 minutes."
   CALL say_c  global.eTxtHi || "          CRONRGF /B"
   CALL say_c "          .. show usage of CRONRGF without colors"

   EXIT 0

/*
   write to logfile & close logfile thereafter
*/
WRITE_LOG: PROCEDURE EXPOSE global.
   CALL LINEOUT global.eLogFile, ARG(1)         /* write log-entry */
   CALL STREAM global.eLogFile, "C", "CLOSE"    /* close logfile */
   RETURN


SAY_C: PROCEDURE EXPOSE global. stemSchedule.
   SAY global.eTxtInf || ARG(1) || global.eScrNorm
   RETURN


ERROR:
   myrc        = RC
   errorlineno = SIGL
   errortext   = ERRORTEXT(myrc)
   errortype   = CONDITION("C")
   problem     = "Cause: Probably caused by a user-interrupt while in INTERPRET-statement."
   CALL stop_it myrc":" errortext "in line # ["errorlineno"] REXX-SIGNAL: ["errortype"] ===>" problem

