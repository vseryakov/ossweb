# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001
#
# $Id: db.tcl 2898 2007-01-29 23:33:54Z vlad $

# Database dispatcher for SQL statements, performs lookup in the SQL dictionary
# and returns full SQL statement by ID if given value is id or returns the given
# statement as is..
# If SQL file was modified, reloads the file, all SQL statements are cached
# in nsv_ array.
# - data is the name of variable with complete SQL statement, Tcl or XQL ID in
#   which case it should begin with sql:, resolved statement will replace
#   this variable's contents
# Returns XQL ID or SQL/TCL strings if it is not is sql: format
proc ossweb::db::xql { data { level "" } { vars "" } { varray "" } } {

    upvar $data var

    switch -glob -- $var {
     tcl:* {
        # Tcl script
        set script [string range $var 4 end]
        # Instantiate local variables
        ossweb::db::dbvars set $level $vars ${varray}
        if { [catch { set var [uplevel #$level $script] } errmsg] } {
          ns_log Error ossweb::db::xql: $script: $errmsg
          ossweb::db::dbvars restore $level
          error "Tcl query failed"
        }
        ossweb::db::dbvars restore $level
        return TCL
     }

     sql:* {
        # SQL statement in XQL definition
        set sql_id [string range $var 4 end]

        if { [nsv_get __ossweb_sql xql:loaded] == 0 } {
          # Check modification time on SQL query file, load file
          # if it was changed or for the first time, try to find
          # more specific file matching current request
          # Try to cache all filesystem calls, first time we check real files and then
          # only local cache for file existence and modification time
          set path [ossweb::config server:path:xql [ns_info home]/xql]
          if { ![ns_filestat $path stat] } {
            error "XQL path $path is invalid"
          }
          # Check for additions/deletions
          if { [nsv_get __ossweb_sql xql:mtime] != $stat(mtime) } {
            nsv_set __ossweb_sql xql:mtime $stat(mtime)
            nsv_set __ossweb_sql xql:files ""
          }
          # Check every .xql file
          if { [set xql_files [nsv_get __ossweb_sql xql:files]] == "" } {
            set xql_files [glob -nocomplain $path/*.xql]
            nsv_set __ossweb_sql xql:files $xql_files
          }
          # In development mode check local directory as well for a directoryname.xql
          if { ![set ::ossweb::adp::adp_cache] && [set curdir [ossweb::adp::DirName]] != "" } {
            lappend xql_files $curdir/[file tail $curdir].xql
          }
          ::foreach file $xql_files {
            if { ![ns_filestat $file stat] } {
              continue
            }
            set mtime0 $stat(mtime):$stat(size):$stat(ino):$stat(dev)
            if { [nsv_exists __ossweb_sql file:$file] } {
              set mtime1 [nsv_get __ossweb_sql file:$file]
            } else {
              set mtime1 0
            }
            if { $mtime1 == $mtime0 } {
              continue
            }
            if { [catch {
              set count 0
              set pos 0
              set text [ossweb::read_file $file]
              while {1} {
                if { [set start [string first "<query " $text $pos]] == -1 ||
                     [set pos [string first "</query>" $text $pos]] == -1 } {
                  break
                }
                # Parse query name
                set data [string range $text $start [incr pos 8]]
                if { ![regexp {<query.+name="([^\"]+)".*>} $data d name] } {
                  continue
                }
                # Parse query SQL
                set key ""
                set spos 0
                while {1} {
                  if { [set sstart [string first "<sql" $data $spos]] == -1 ||
                       [set spos [string first "</sql>" $data $spos]] == -1 } {
                     break
                  }
                  set sql [string range $data $sstart [incr spos 6]]
                  if { ![regexp {<sql[ ]+dbtype="([^\"]+)".*>} $sql d dbtype] } {
                    set dbtype ""
                  }
                  if { [regexp {<sql[^>]*>(.+)</sql>} $sql d sql] } {
                    if { $dbtype != "" } {
                      set key $name:[string tolower $dbtype]
                    } else {
                      set key $name
                    }
                    regsub -all {@([^@]+)@} $sql {[string map {' '' $ \\\\$ \\\\ \\\\\\\\} $\1]} sql
                    nsv_set __ossweb_sql $key $sql
                  }
                  incr count
                }
                # Parse query columns
                if { $key != "" &&
                     [set sstart [string first "<vars>" $data 0]] > -1 &&
                     [set spos [string first "</vars>" $data 0]] > -1 } {
                  set vars [string range $data [incr sstart 7] [incr spos -1]]
                  nsv_set __ossweb_sql vars:$key [string trim $vars]
                }
              }
              ns_log Notice ossweb::db::xql: $file: loaded, $count queries
            } errMsg] } {
              ns_log Error ossweb::db::xql: $file: $errMsg
            }
            # Save last modification time
            nsv_set __ossweb_sql file:$file $mtime0
          }
          # Do not check modification time any more
          if { [ossweb::config server:check:xql] == "never" } {
            nsv_set __ossweb__sql xql:loaded 1
          }
        }
        if { [set dbtype [ossweb::conn db:type]] != "" &&
             [nsv_exists __ossweb_sql $sql_id:$dbtype] } {
          append sql_id :$dbtype
        }

        if { ![nsv_exists __ossweb_sql $sql_id] } {
          error "XQL query '$sql_id ($dbtype)' not found"
        }
        if { $level == "" } {
          set level [expr [info level] - 2]
        }
        # Setup query vars
        if { [nsv_exists __ossweb_sql vars:$sql_id] } {
          ::foreach { _k _v } [nsv_get __ossweb_sql vars:$sql_id] {
            upvar #$level $_k _var
            if { ![info exists _var] || $_var == "" } {
              set vars [linsert $vars 0 $_k $_v]
            }
          }
        }
        # Mark that we are inside xql
        if { [ossweb::conn xql:id] == "" } {
          ossweb::conn -set xql:id $sql_id
        }
        # Instantiate local variables
        ossweb::db::dbvars set $level $vars ${varray}

        # Build SQL statement
        if { [catch { set var [uplevel #$level "subst \[nsv_get __ossweb_sql $sql_id\]"] } errmsg] } {
          ns_log Error ossweb::db::xql: $sql_id: $errmsg
          ossweb::db::dbvars restore $level
          ossweb::conn -unset xql:id
          error "XQL query failed"
        }
        # Restore local variables at the top level only because filters
        # may call ossweb::db::xql inside maps and we want to keep variables
        # during the top level xql
        if { [ossweb::conn xql:id] == $sql_id } {
          ossweb::db::dbvars restore $level
          ossweb::conn -unset xql:id
        }
        return $sql_id
     }

     default {
        if { [regsub -all {@([^@]+)@} $var {[string map {' '' $ \\\\$ \\\\ \\\\\\\\} $\1]} var] } {
           if { [catch { set var [uplevel #$level "subst {$var}" ] } errmsg] } {
              ns_log Error ossweb::db::xql: $errmsg
              error "SQL query failed"
           }
        }
        return SQL
     }
    }
}

# Returns database list
proc ossweb::db::databases {} {

    return [ossweb::db::list sql:ossweb.db.database.list]
}

# Returns table columns
proc ossweb::db::columns { table_name { attnum 0 } } {

    return [ossweb::db::list sql:ossweb.db.table.column.names]
}

# Returns tables
proc ossweb::db::tables { args } {

    ns_parseargs { {-regex ""} } $args

    set tables [ossweb::db::list sql:ossweb.db.table.list]

    if { $regex != "" } {
      set tlist [::list]
      ::foreach table $tables {
        if { [regexp $regex $table] } {
          lappend tlist $table
        }
      }
      set tables $tlist
    }
    return $tables
}

# Returns the first column of the result.
# If the query doesn't return a row, returns -default value
#  -cache specifies name of the cache item under which to save results
#  -refresh t forces flushing cached results
#  -timeout specifies timeout for cached results
#  -default if values is null return default
proc ossweb::db::value { sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-release f}
                   {-default ""}
                   {-refresh f}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-timeout ""}
                   {-debug f}
                   {-vars ""}
                   {-vars:array ""}
                   {-colname ""}
                   {-colindex 0}
                   {-map "" }
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $cache != "" } {
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      return [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::value $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -default $default \
                                -debug $debug \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -map $map \
                                -colname $colname \
                                -colindex $colindex]
                   } -expires $timeout -force $refresh]
    }

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set id [ossweb::db::xql sql $level $vars ${vars:array}]

    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::value: $sql
    }

    if [catch { set query [ns_db 0or1row $db $sql] } errmsg] {
      if { $debug == "t" } {
        ns_log Error "ossweb::db::value: $id: $errmsg: $sql"
      }
      ::ossweb::db::parse_error $errmsg $sql $id
      if { $release == "t" } {
        ossweb::db::release
      }
      return
    }
    set result $default
    if { $query == "" } {
      return $result
    }
    if { $colname != "" } {
      set colindex [ns_set ifind $query $colname]
    }
    if { $colindex >= 0 && $colindex < [ns_set size $query] } {
      set result [ns_set value $query $colindex]
    }
    if { $map != "" } {
      set result [string map $map $result]
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    return $result
}

# Returns the first column of each row and returns it as a Tcl list
#  -cache specifies name of the cache item under which to save results
#  -refresh t forces flushing cached results
#  -timeout specifies timeout for cached results
#  -colindex by default is 0, can be used to specify column
#  -colname column name to be returned
#  -all if true all columns will be added to the resulting list
#  -unique t will return result of lsort -unique
proc ossweb::db::list { sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-refresh f}
                   {-debug f}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-colindex 0}
                   {-colname ""}
                   {-timeout ""}
                   {-release f}
                   {-maxrows ""}
                   {-unique f}
                   {-all f}
                   {-map "" }
                   {-vars ""}
                   {-vars:array "" }
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $level == "" } { set level [expr [info level]-1] }

    if { $cache != "" } {
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      return [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::list $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -all $all \
                                -map $map \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -unique $unique \
                                -maxrows $maxrows \
                                -debug $debug \
                                -colname $colname \
                                -colindex $colindex]
                   } -expires $timeout -force $refresh]
    }

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::list: $sql
    }

    if [catch { set query [ns_db select $db $sql] } errmsg] {
       if { $debug == "t" } {
         ns_log Error ossweb::db::list: $id: $errmsg: $sql
       }
       ::ossweb::db::parse_error $errmsg $sql $id
       if { $release == "t" } {
         ossweb::db::release
       }
       return
    }
    # No records found
    if { $query == "" } {
      return
    }
    set rowcount 0
    set result [::list]
    while { [ns_db getrow $db $query] } {
       incr rowcount
       set size [ns_set size $query]
       # Return column by name
       if { $colname != "" } {
         for { set i 0 } { $i < $size } { incr i } {
           if { [ns_set key $query $i] == $colname } {
             if { $map != "" } {
               set value [string map $map [ns_set value $query $i]]
             } else {
               set value [ns_set value $query $i]
             }
             lappend result $value
             break
           }
         }
         continue
       }
       # Return column by index
       lappend result [ns_set value $query $colindex]
       if { $all == "t" } {
         for { set i 1 } { $i < $size } { incr i } {
           set value [ns_set value $query $i]
           if { $map != "" } {
             set value [string map $map $value]
           }
           lappend result $value
         }
       }
       # Stop if maxrows has been reached
       if { $rowcount == $maxrows } {
         ns_db flush $db
         break
       }
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    # Return just unique values
    if { $unique == "t" } {
      set result [lsort -unique $result]
    }
    return $result
}

# Returns a list of Tcl lists with each sublist containing the columns
# returned by the database; if no rows are returned by the
# database, returns the empty string
#  -cache specifies name of the cache item under which to save results
#  -refresh t forces flushing cached results
#  -timeout specifies timeout for cached results
#  -array t tells to returns list of arrays
#  -colcount tells how many columns to take from the query
#  -colindex if given will return only specified column
#  -colname if given will return only specified column
#  -unique specifies colindex to be used for lsort -unique
proc ossweb::db::multilist { sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-refresh f}
                   {-debug f}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-timeout ""}
                   {-release f}
                   {-vars ""}
                   {-vars:array ""}
                   {-array f}
                   {-plain f}
                   {-acl ""}
                   {-map ""}
                   {-unique ""}
                   {-maxrows ""}
                   {-arrayvars ""}
                   {-colcount ""}
                   {-colindex ""}
                   {-colname ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $cache != "" } {
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      return [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::multilist $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -plain $plain \
                                -map $map \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -unique $unique \
                                -array $array \
                                -arrayvars $arrayvars \
                                -maxrows $maxrows \
                                -debug $debug \
                                -colcount $colcount \
                                -colname $colname \
                                -colindex $colindex]
                   } -expires $timeout -force $refresh]
    }

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::multilist: $id: $sql
    }

    if [catch { set query [ns_db select $db $sql] } errmsg] {
       if { $debug == "t" } {
         ns_log Error ossweb::db::multilist: $id: $errmsg: $sql
       }
       ::ossweb::db::parse_error $errmsg $sql $id
       if { $release == "t" } {
         ossweb::db::release
       }
       return
    }
    if { $query == "" } {
      return
    }
    set rowcount 0
    set result [::list]
    while { [ns_db getrow $db $query] } {
        incr rowcount
        set row [::list]
        # Convert Tcl arrays into Tcl variables
        ::foreach vname $arrayvars {
          ::foreach { vk vv } [ns_set iget $query $vname] {
            ns_set update $query $vk $vv
          }
        }
        set size [ns_set size $query]
        # Return only specified column by index
        if { $colindex != "" } {
          if { $array == "t" } {
            lappend row [ns_set key $query $i]
          }
          if { $map != "" } {
            set value [string map $map [ns_set value $query $colindex]]
          } else {
            set value [ns_set value $query $colindex]
          }
          lappend row $value
          set size 0
        }
        for { set i 0 } { $i < $size } { incr i } {
          # Return only specified column by name
          if { $colname != "" && [ns_set key $query $i] == $colname } {
            if { $array == "t" } {
              lappend row [ns_set key $query $i]
            }
            set value [ns_set value $query $i]
            if { $map != "" } {
              set value [string map $map $value]
            }
            lappend row $value
            break
          }
          # All columns
          if { $array == "t" } {
            lappend row [ns_set key $query $i]
          }
          set value [ns_set value $query $i]
          if { $map != "" } {
            set value [string map $map $value]
          }
          lappend row $value
          # Stop if reached column limit
          if { [string is integer -strict $colcount] && $i >= $colcount } {
            break
          }
        }
        if { $plain == "f" } {
          lappend result $row
        } else {
          ::foreach item $row {
            lappend result $item
          }
        }
        # Stop if maxrows has been reached
        if { $rowcount == $maxrows } {
          ns_db flush $db
          break
        }
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    if { $unique != "" } {
      set result [lsort -unique -index $unique $result]
    }
    return $result
}

# Performs the SQL query $sql that returns 0 or 1 row,
# setting variables to column values.
#  -prefix specifies additional name prefix to make column names different
#  -cache specifies name of the cache item under which to save results
#  -refresh t forces flushing cached results
#  -timeout specifies timeout for cached results
#  -arrayvars specifies list of variables that will contain Tcl arrays and need to be
#            converted into Tcl variables
# Returns -1 in case of error
proc ossweb::db::multivalue { sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-prefix ""}
                   {-refresh f}
                   {-error f}
                   {-array ""}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-timeout ""}
                   {-release f}
                   {-debug f}
                   {-local t}
                   {-map ""}
                   {-vars ""}
                   {-vars:array ""}
                   {-arrayvars ""}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return -1 }

    if { $cache != "" } {
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      set result [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::multilist $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -plain t \
                                -array t \
                                -map $map \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -arrayvars $arrayvars \
                                -debug $debug]
                   } -expires $timeout -force $refresh]

      if { $result == "" } {
        return -1
      }
      ::foreach { name value } $result {
        if { $array != "" } {
          upvar #$level ${array}($name) _var
          set _var $value
        } else {
          if { $local == "t" } {
            upvar #$level ${prefix}$name _var
            set _var $value
          }
        }
      }
      return 0
    }
    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return -1
    }
    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::multilist: $sql
    }

    if { [catch { set query [ns_db 0or1row $db $sql] } errmsg] } {
       if { $debug == "t" } {
         ns_log Error "ossweb::db::multivalue: $id: $errmsg: $sql"
       }
       if { $error == "t" } {
         error $errmsg
       }
       ::ossweb::db::parse_error $errmsg $sql $id
       if { $release == "t" } {
         ossweb::db::release
       }
       return -1
    }
    # No records found
    if { $query == "" } {
      return -1
    }
    set i 0
    # Convert Tcl arrays into Tcl variables
    ::foreach vname $arrayvars {
      ::foreach { vk vv } [ns_set iget $query $vname] {
        ns_set update $query $vk $vv
      }
    }
    set size [ns_set size $query]
    while { $i < $size } {
      set name [ns_set key $query $i]
      set value [ns_set value $query $i]
      if { $map != "" } {
        set value [string map $map $value]
      }
      if { $array != "" } {
        upvar #$level ${array}($name) _var
        set _var $value
      } else {
        if { $local == "t" } {
          upvar #$level ${prefix}$name _var
          set _var $value
        }
      }
      incr i
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    return 0
}

# Process a multirow query.  Use an array for each row in the
# result.  Arrays are named name:0, name:1, name:2 etc.  The variable
# name:rowcount is also defined for checking and iteration.
#  -cache t specifies that result should be cached
#  -refresh t forces flushing cached results
#  -timeout specifies timeout for cached results
#  -replace_null specifies value for null columns
#  -level specifies frame level where to create datasource
#  -norows t tells no to create name:rownum records. only execute
#                  eval script for each row
#  -maxrows specifies max number of records
#  -local specifies that in eval script instead of row array create local variables
#  -eval execute cript for each record, columns can be accessed via row array
# Performing continue inside the eval script will cause the current record to be ignored.
# Returngin or breaking the eval script will cause the query to stop.
proc ossweb::db::multirow { name sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-eval ""}
                   {-eval2 ""}
                   {-local f}
                   {-replace_null ""}
                   {-set_null ""}
                   {-refresh f}
                   {-debug f}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-cache:global t}
                   {-norows f}
                   {-nocolumns f}
                   {-maxrows 1000}
                   {-timeout ""}
                   {-error f}
                   {-release f}
                   {-map ""}
                   {-vars ""}
                   {-vars:array ""}
                   {-arrayvars ""}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    upvar #$level $name:rowcount rowcount ${name}:columns columns
    set rowcount 0

    # Return cached records
    if { $cache != "" } {
      # Build cache name
      if { $cache == "t" } {
        set cache $name
      }
      switch -- ${cache:global} {
       f { append cache :[ossweb::conn user_id] }
       s { append cache :[ossweb::conn session_id] }
      }
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      set result [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::multilist $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -maxrows $maxrows \
                                -array t \
                                -map $map \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -arrayvars $arrayvars \
                                -debug $debug]
                   } -expires $timeout -force $refresh]

      ::foreach rec $result {
        incr rowcount
        upvar #$level $name:$rowcount row
        array set row $rec
        # Build column array
        if { $rowcount == 1 } {
          ::foreach var $rec {
            lappend columns $var
          }
        }
        set rec [array names row]
        # Replace empty values
        if { $replace_null != "" } {
          ::foreach var $rec {
            if { $row(var) == "" } {
              set row($var) $replace_null
            }
          }
        }
        # Setup local variable for each column in the calling frame
        if { $local == "t" } {
          ::foreach var $rec {
            upvar #$level $var _var
            set _var $row($var)
          }
        }
        set row(rownum) $rowcount
        # Execute custom code for each row
        if { $eval != "" } {
          set rc [catch { uplevel #$level "upvar 0 ${name}:$rowcount row; $eval; $eval2" } errmsg]
          # Examine status for special situations
          switch $rc {
           0 {}
           4 {
               incr rowcount -1
               continue
             }
           2 -
           3 {
               incr rowcount -1
               break
           }
           default {
               global errorInfo
               ::ossweb::conn::log Error ossweb::db::multirow $name: $errmsg: $errorInfo
           }
          }
        }
        # Replace all null columns with specified value
        if { $set_null != "" } {
          ::foreach var [array names row] {
            if { $row($var) == "" } {
              set row($var) $set_null
            }
          }
        }
        if { $norows == "t" } {
          unset row
        }
      }
      # Set column list only if we have records or it doesn't exist
      if { $nocolumns == "t" || ![info exists columns] } {
        set columns ""
      }
      return $rowcount
    }

    # Process database directly
    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return -1
    }

    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::multirow: $name: $id: $sql
    }

    if { [catch { set query [ns_db select $db $sql] } errmsg] } {
      if { $debug == "t" } {
        ns_log Error ossweb::db::multirow: $id: $errmsg: $sql
      }
      if { $release == "t" } {
        ossweb::db::release
      }
      if { $error == "t" } {
        error $errmsg
      }
      ::ossweb::db::parse_error $errmsg $sql $id
      return -1
    }

    while { [ns_db getrow $db $query] } {
      incr rowcount
      # Convert Tcl arrays into Tcl variables
      ::foreach vname $arrayvars {
        ::foreach { vk vv } [ns_set iget $query $vname] {
          ns_set update $query $vk $vv
        }
      }
      set size [ns_set size $query]
      # Build column array
      if { $rowcount == 1 } {
        set columns {}
        for { set i 0 } { $i < $size } { incr i } {
          lappend columns [ns_set key $query $i]
        }
      }
      upvar #$level ${name}:$rowcount row
      set row(rownum) $rowcount
      for { set i 0 } { $i < $size } { incr i } {
        set var [ns_set key $query $i]
        set value [ns_set value $query $i]
        set value [ns_set value $query $i]
        if { $map != "" } {
          set value [string map $map $value]
        }
        # Replace empty values
        if { $replace_null != "" && $value == "" } {
          set row($var) $replace_null
        } else {
          set row($var) $value
        }
        # Setup local variable for each column in the calling frame
        if { $local == "t" } {
          upvar #$level $var _var
          set _var $value
        }
      }
      # Execute custom code for each row
      if { $eval != "" } {
        set rc [catch { uplevel #$level "upvar 0 ${name}:$rowcount row; $eval; $eval2" } errmsg]
        # Examine status for special situations
        switch $rc {
         0 {}
         4 {
             incr rowcount -1
             continue
           }
         2 -
         3 {
             incr rowcount -1
             ns_db flush $db
             break
         }
         default {
             global errorInfo
             ossweb::conn::log Error ossweb::db::multirow $name: $sql: $errmsg: $errorInfo
         }
        }
      }
      # Replace all null columns with specified value
      if { $set_null != "" } {
        ::foreach col [array names row] {
          if { $row($col) == "" } { set row($col) $set_null }
        }
      }
      if { $norows == "t" } {
        unset row
      }
      # Stop if maxrows has been reached
      if { $rowcount == $maxrows } {
        ns_db flush $db
        break
      }
    }
    # Set column list only if we have records or it doesn't exist
    if { $nocolumns == "t" || ![info exists columns] } {
      set columns ""
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    return $rowcount
}

# Queries database and performs displaying results in pages. Datasource
# as for multirow will be created. Performs caching of query results for specified amount
# of time.
#  name datasource name
#  query1 the query that returns the IDs
#  query2 the query that returns the actual rows containing IN (CURRENT_PAGE_SET).
#  -timeout the lifetime of a query result in seconds, after which the query must be refreshed.
#  -pagesize the number of rows to display on a single page.
#  -eval Run the script for each row
#  -eval_single Run the script if result contains one single record only
#  -page specifies page to be displayed
proc ossweb::db::multipage { id query1 query2 args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-debug f}
                   {-eval ""}
                   {-cache ""}
                   {-refresh f}
                   {-eval2 ""}
                   {-query ""}
                   {-url ""}
                   {-eval_single ""}
                   {-replace_null ""}
                   {-set_null ""}
                   {-pagesize 25}
                   {-timeout 600}
                   {-page 1}
                   {-local f}
                   {-force f}
                   {-cmd cmd}
                   {-cmd_name view}
                   {-error f}
                   {-datatype int}
                   {-release f}
                   {-vars ""}
                   {-vars:array ""}
                   {-map ""}
                   {-arrayvars ""}
                   {-norows f}
                   {-user_id {[ossweb::conn user_id]}}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    # Declare required multirow vars
    upvar #$level $id:mp properties $id:rowcount rowcount $id:columns columns
    set rowcount 0

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return -1
    }
    set ids [ossweb::db::list $query1 \
                  -level $level \
                  -cache mp:$id:$user_id \
                  -cache:auto t \
                  -debug $debug \
                  -vars $vars \
                  -vars:array ${vars:array} \
                  -timeout $timeout \
                  -refresh $force]
    # Page information
    set ids [ossweb::sql::multipage $id:mp \
                  -ids $ids \
                  -cmd $cmd \
                  -level $level \
                  -cmd_name $cmd_name \
                  -pagesize $pagesize \
                  -timeout $timeout \
                  -query $query \
                  -url $url \
                  -user_id $user_id \
                  -page $page]
    set rownum 0
    # No records found
    if { !$properties(page_rowcount) } {
      return 0
    }
    set sql_id [ossweb::db::xql query2 $level $vars ${vars:array}]
    if { ![regsub -all CURRENT_PAGE_SET $query2 [ossweb::sql::list $ids $datatype] query2] } {
      ns_log Error ossweb::db::multipage: $sql_id: OSSWEB: ossweb::db::multipage: Token CURRENT_PAGE_SET not found in page data query: $query2
      error "OSSWEB: Invalid query"
    }
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::multipage: $id: $sql_id: $query2
    }

    # Run single eval script if we have only one record
    if { $properties(rowcount) == 1 && $eval_single != "" } {
      set eval $eval_single
    }
    ossweb::convert::list_to_array $ids varray

    if [catch { set query [ns_db select $db $query2] } errmsg] {
      if { $debug == "t" } {
        ns_log Error ossweb::db::multipage $sql_id: $errmsg: $query2
      }
      if { $release == "t" } {
        ossweb::db::release
      }
      if { $error == "t" } {
        error $errmsg
      }
      ::ossweb::db::parse_error $errmsg $query2 $sql_id
      return -1
    }
    while { [ns_db getrow $db $query] } {
      incr rownum
      # Convert Tcl arrays into Tcl variables
      ::foreach vname $arrayvars {
        ::foreach { vk vv } [ns_set iget $query $vname] {
          ns_set update $query $vk $vv
        }
      }
      set size [ns_set size $query]
      # Build column array
      if { $rownum == 1 } {
        set columns {}
        for { set i 0 } { $i < $size } { incr i } {
          lappend columns [ns_set key $query $i]
        }
      }
      # Put each row in particular order which was returned by the first query,
      # use first column value as an ID
      if { [catch { set i $varray([ns_set value $query 0]) } errmsg] } {
        ns_log Error ossweb::db::multipage: $id: [ns_set value $query 0]: $errmsg, should be ID column first
        continue
      }
      upvar #$level $id:$i row
      set row(rownum) $rownum
      for { set i 0 } { $i < $size } { incr i } {
        set key [ns_set key $query $i]
        set value [ns_set value $query $i]
        set value [ns_set value $query $i]
        if { $map != "" } {
          set value [string map $map $value]
        }
        if { $replace_null != "" && $value == "" } {
          set row($key) $replace_null
        } else {
          set row($key) $value
        }
      }
      incr rowcount
    }
    # Execute custom code for each row
    if { $eval != "" } {
      for { set i 1 } { $i <= $rowcount }  { incr i } {
        upvar #$level $id:$i row
        # Setup local variable for each column in the calling frame
        if { $local == "t" } {
          foreach key [array get names] {
            upvar #$level $key var
            set var $row($key)
          }
        }
        set rc [catch { uplevel #$level "upvar 0 $id:$i row;$eval; $eval2" } errmsg]
        # Examine status for special situations
        switch $rc {
         0 {}
         4 {
           # Shift rows backward
           for { set j $i } { $j < $rowcount } { incr j } {
             upvar #$level $id:$j row
             upvar #$level $id:[expr $j+1] row2
             array set row [array get row2]
           }
           incr i -1
           incr rowcount -1
           continue
         }
         2 -
         3 {
           ns_db flush $db
           break
         }
         default {
           global errorInfo
           ::ossweb::conn::log Error ossweb::db::multipage $sql_id: $errmsg: $errorInfo
           ns_db flush $db
           return -1
         }
        }
        # Replace all null columns with specified value
        if { $set_null != "" && $norows != "t" } {
          ::foreach col [array names row] {
            if { $row($col) == "" } {
              set row($col) $set_null
            }
          }
        }
      }
      if { $norows == "t" } {
        unset row
        continue
      }
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    return $rowcount
}

# Usage: ossweb::db::foreach sql code [on_empty_code]
# Performs the SQL query $sql, executing code once for each row with
# variables set to column values.
proc ossweb::db::foreach { sql args } {

    # Script can be passed as second argument or via -eval arg
    if { ![string match "-*" [lindex $args 0]] } {
      set eval [lindex $args 0]
      set args [lreplace $args 0 0]
    }
    ns_parseargs { -eval
                   {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-release f}
                   {-prefix ""}
                   {-columns ""}
                   {-on_empty ""}
                   {-error f}
                   {-debug f}
                   {-refresh f}
                   {-vars ""}
                   {-vars:array ""}
                   {-cache ""}
                   {-cache:auto f}
                   {-cache:flush ""}
                   {-arrayvars ""}
                   {-array ""}
                   {-map ""}
                   {-timeout ""}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $columns != "" } {
      upvar $columns column_list
      set column_list [::list]
    }
    upvar rownum rownum
    set rownum 0

    if { $cache != "" } {
      # Dynamic cache, re-read from DB if SQL changed
      if { ${cache:auto} == "t" } {
        set cache:flush $cache:*
        ossweb::db::xql sql $level $vars ${vars:array}
        set cache $cache:[ns_sha1 $sql]
      }
      set result [ossweb::cache::run __ossweb_dbcache $cache {
                   if { ${cache:flush} != "" } {
                     ossweb::db::cache clear ${cache:flush} $cache
                   }
                   return [ossweb::db::multilist $sql \
                                -level $level \
                                -db $db \
                                -release $release \
                                -array t \
                                -arrayvars $arrayvars \
                                -vars $vars \
                                -vars:array ${vars:array} \
                                -map $map \
                                -debug $debug]
                   } -expires $timeout -force $refresh]

      ::foreach rec $result {
         incr rownum
         ::foreach { name value } $rec {
           if { $array != "" } {
             upvar #$level ${array}($prefix$name) var
           } else {
             upvar #$level $prefix$name var
           }
           set var $value
           # Save columns list
           if { $rownum == 1 && $columns != "" } {
             lappend column_list $name
           }
         }
         set rc [catch { uplevel 1 $eval } errmsg]
         switch $rc {
          0 -
          4 {}
          2 -
          3 {
            ns_db flush $db
            break
          }
          default {
            global errorInfo errorCode
            if { $release == "t" } {
              ossweb::db::release
            }
            error $errmsg $errorInfo $errorCode
          }
         }
      }
      if { $rownum == 0 && $on_empty != "" } {
        uplevel 1 $on_empty
      }
      return
    }

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }

    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::foreach: $sql
    }

    if [catch { set query [ns_db select $db $sql] } errmsg] {
       if { $debug == "t" } {
         ns_log Error ossweb::db::foreach: $id: $errmsg: $sql
       }
       if { $release == "t" } {
         ossweb::db::release
       }
       if { $error == "t" } {
         error $errmsg
       }
       ::ossweb::db::parse_error $errmsg $sql $id
       return
    }
    while { [ns_db getrow $db $query] } {
      incr rownum
      # Convert Tcl arrays into Tcl variables
      ::foreach vname $arrayvars {
        ::foreach { vk vv } [ns_set iget $query $vname] {
          ns_set update $query $vk $vv
        }
      }
      for { set i 0 } { $i < [ns_set size $query] } { incr i } {
        set name [ns_set key $query $i]
        if { $array != "" } {
          upvar #$level ${array}($prefix$name) var
        } else {
          upvar #$level $prefix$name var
        }
        if { $map != "" } {
          set var [string map $map [ns_set value $query $i]]
        } else {
          set var [ns_set value $query $i]
        }
        # Save columns list
        if { $rownum == 1 && $columns != "" } {
          lappend column_list $name
        }
      }
      set rc [catch { uplevel 1 $eval } errmsg]
      switch $rc {
        0 -
        4 {}
        2 -
        3 {
           ns_db flush $db
           break
        }
        default {
           global errorInfo errorCode
           if { $release == "t" } {
             ossweb::db::release
           }
           error $errmsg $errorInfo $errorCode
        }
      }
    }
    # If the on_empty is defined, go ahead and run it.
    if { $rownum == 0 && $on_empty != "" } {
      uplevel 1 $on_empty
    }
    if { $release == "t" } {
      ossweb::db::release
    }
    return
}

# Executes SQL statement, returns 0 if successful
# All user/OSS related messages will be placed into global message
# window.
proc ossweb::db::exec { sql args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-error f}
                   {-debug f}
                   {-vars ""}
                   {-vars:array ""}
                   {-cmd ""}
                   {-msg f}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return -1
    }

    set id [ossweb::db::xql sql $level $vars ${vars:array}]
    if { $debug == "t" } {
      ossweb::conn::log Notice ossweb::db::exec: $sql
    }

    # Run specified cmd, may be tracing, logging
    if { $cmd != "" && [$cmd $sql] } {
      return 0
    }
    # Execute SQL statement
    if [catch { ns_db exec $db $sql } errmsg] {
       # Propagate error up
       if { $error == "t" } {
         error $errmsg
       }
       if { $msg == "t" } {
         ossweb::conn::set_msg -color red $errmsg
       } else {
         ::ossweb::db::parse_error $errmsg $sql $id
       }
       return -1
    }
    return 0
}

# Perform SQL INSERT into given table
proc ossweb::db::insert { table args } {

    ns_parseargs { {-insertargs ""} {-skip_null t} {-skip ""} {-array ""} {-columns ""} args } $args

    # Consult database for table columns
    if { $columns == "" } {
      set columns [ossweb::sql::columns $table]
    }
    return [uplevel ossweb::db::exec "{tcl:subst {INSERT INTO $table \[ossweb::sql::insert_values $insertargs -array {$array} -full t -skip_null $skip_null -skip {$skip} {$columns}\]}}" $args]
}

# Perform SQL UPDATE in the given table
proc ossweb::db::update { table args } {

    ::foreach { args where } [ossweb::sql::dbargs $args] {}

    ns_parseargs { {-updateargs ""} {-skip_null t} {-skip ""} {-array ""} {-columns ""} args } $args

    # Consult database for table columns
    if { $columns == "" } {
      set columns [ossweb::sql::columns $table]
    }
    return [uplevel ossweb::db::exec "{tcl:subst {UPDATE $table SET \[ossweb::sql::update_values $updateargs -array {$array} -skip_null $skip_null -skip {$skip} {$columns}\] WHERE $where}}" $args]
}

# Perform SQL DELETE in the given table
proc ossweb::db::delete { table args } {

    ::foreach { args where } [ossweb::sql::dbargs $args] {}

    return [uplevel ossweb::db::exec "{tcl:subst {DELETE FROM $table WHERE $where}}" $args]
}

# Perform SQL SELECT from given table
proc ossweb::db::read { table args } {

    ::foreach { args where } [ossweb::sql::dbargs $args] {}

    ns_parseargs { {-type multivalue} {-columns *} {-filter ""} {-filterargs "" } {-orderby ""} {-limit ""} args } $args

    if { $limit != "" } {
      set limit "LIMIT $limit"
    }
    if { $orderby != "" } {
      set orderby "ORDER BY $orderby"
    }
    return [uplevel ossweb::db::$type "{tcl:subst {SELECT [join $columns ,] FROM $table \[ossweb::sql::filter {$filter} $filterargs -where WHERE -filter {$where}\] $orderby $limit}}" $args]
}

# Perform SQL SELECT from given table
proc ossweb::db::select { table args } {

    ns_parseargs { {-type multilist} args } $args

    return [uplevel ossweb::db::read $table -type "{$type}" $args]
}

# Perform SQL SELECT from given table, returns list of arrays for each row
proc ossweb::db::arrays { table args } {

    return [uplevel ossweb::db::read $table -type multilist $args -array t]
}

# Perform SQL SELECT from given table, execute Tcl script for each row
proc ossweb::db::scan { table args } {

    return [uplevel ossweb::db::read $table -type foreach $args]
}

# Perform check if record exists and if not insert a new one
proc ossweb::db::replace { table args } {

    ::foreach { args where } [ossweb::sql::dbargs $args] {}

    ns_parseargs { {-update t} {-insertargs ""} {-updateargs ""} {-skip_null t} {-skip ""} {-array ""} {-columns ""} args } $args

    if { [ossweb::db::select $table -columns 1 -where $where] == "" } {
      uplevel ossweb::db::insert $table -insertargs "{$insertargs}" -skip_null "{$skip_null}" -skip "{$skip}" -array "{$array}" -columns "{$columns}" $args
    } elseif { $update == "t" } {
      uplevel ossweb::db::update $table -where "{$where}" -updateargs "{$updateargs}" -skip_null "{$skip_null}" -skip "{$skip}" -array "{$array}" -columns "{$columns}" $args
    }
}

# Copy table form one database into another
proc ossweb::db::copy { table dbname1 dbname2 args } {

    ns_parseargs { {-map ""} {-remove ""} {-add ""} } $args

    ossweb::db::release

    if { [ossweb::db::handle $dbname1] == "" } {
      return -1
    }
    if { [catch { set db2 [ns_db gethandle $dbname2] } errmsg] } {
      ns_log Error ossweb::db::copy: $errmsg
      return -1
    }

    set count 0
    ::foreach rec [ossweb::db::arrays $table] {
      incr count
      if { $map != "" } {
        set rec [string map $map $rec]
      }
      array set trec $rec
      ::foreach column $remove {
        set trec($column) ""
      }
      ::foreach { column value } $add {
        set trec($column) $add
      }
      ossweb::db::insert $table -array trec -db $db2
    }
    ossweb::db::release
    catch { ns_db releasehandle $db2 }
    return $count
}

# Perform the block of dml SQL statements as one transaction.
# Returns 1 in case of error occurred or 0 on success.
# sql_list contains a list of SQL statements.
proc ossweb::db::block { sql_list args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-db ""}
                   {-release f}
                   {-vars ""}
                   {-vars:array ""}
                   {-debug f}
                   {-acl ""} } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } {
      return
    }

    # Local variables
    ossweb::db::dbvars set $level $vars ${vars:array}

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return -1
    }
    ossweb::db::begin
    ::foreach sql $sql_list {
      set id [ossweb::db::xql sql]
      if { [catch { ns_db exec $db $sql } errmsg] } {
        ossweb::db::rollback
        if { $debug == "t" } {
          ns_log Error ossweb::db::block: $id: $errmsg: $sql
        }
        ::ossweb::db::parse_error $errmsg $sql $id
        if { $release == "t" } {
          ossweb::db::release
        }
        # Restore local variable to their original state
        ossweb::db::dbvars restore $level
        return -1
      }
    }
    ossweb::db::commit
    # Restore local variable to their original state
    ossweb::db::dbvars restore $level
    if { $release == "t" } {
      ossweb::db::release
    }
    return 0
}

# Returns a database connection handle. Returns the same database handle
# for all subsequent calls until ossweb::db::release is called.  This allows
# the same handle to be used easily across multiple procedures.
# Returns A database handle
proc ossweb::db::handle { { pool "" } { count 1 } } {

    set db [ossweb::conn db:handle]
    if { $db != "" } {
      if { $pool == "" || [ossweb::conn db:pool] == $pool } {
        return $db
      }
      catch { ns_db releasehandle $db }
    }

    set path "ns/server/[ns_info server]/ossweb"
    # Try project specific first, then global default, save default pool in the conn
    # for subsequent call to minimize config lock contention
    if { $pool == "" } {
      if { [set pool [ossweb::conn db:name]] == "" } {
        # Project specific database pool, use actual directory from the url
        set pool [ns_config $path server:database:[ns_config $path server:project]]
        # Global database pool
        if { $pool == "" } {
          set pool [ns_config $path server:database ossweb]
        }
        # Database access disabled
        if { $pool == "0" } {
          return
        }
        ossweb::conn -set db:name $pool
      }
    }
    if { [catch { set db [ns_db gethandle $pool $count] } errmsg] } {
      ns_log Error ossweb::db::handle: $db/$pool/$count: $errmsg
      return
    }
    # Keep in the cache for subsequent calls
    ossweb::conn -set db:handle $db db:pool [ns_db poolname $db] db:type [string tolower [ns_db dbtype $db]]
    return $db
}

# Set given handle as current database handle
proc ossweb::db::sethandle { db } {

    ossweb::db::release
    ossweb::conn -set db:handle $db db:pool [ns_db poolname $db]
    return $db
}

# Releases a database handle previously requested with ossweb::db::handle.
proc ossweb::db::release { args } {

    set db [ossweb::conn db:handle]
    if { $db != "" } {
      ossweb::db::commit -db $db
      catch { ns_db releasehandle $db }
      ossweb::conn -set db:handle "" db:pool ""
    }
}

# Work with database cache directly
proc ossweb::db::cache { cmd name { value "" } } {

    switch -- $cmd {
     get {
       ossweb::cache::get __ossweb_dbcache $name -default $value
     }

     set {
       ossweb::cache::put __ossweb_dbcache $name $value
     }

     keys -
     names {
       return [ossweb::cache::keys __ossweb_dbcache $name]
     }

     flush {
       ossweb::cache::flush __ossweb_dbcache $name
     }

     clear {
       ::foreach key [ossweb::cache::keys __ossweb_dbcache $name] {
         if { $key != $value } {
           ossweb::cache::flush __ossweb_dbcache $key
         }
       }
     }
    }
}

# Begins a database transaction, nested calls are allowed.
# Returns 0 on success, -1 on error
proc ossweb::db::begin { args } {

    ns_parseargs { {-db ""} } $args

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set trans [ossweb::conn -incr $db:transaction]
    if { $trans <= 1 } {
      if { [catch { ns_db dml $db "BEGIN TRANSACTION" } errmsg] } {
        ns_log Error "ossweb::db::begin: $errmsg"
        return -1
      }
      ossweb::conn -set $db:transaction 1
    }
    return 0
}

# Commits a database transaction.
# Returns 0 on success, -1 on error
proc ossweb::db::commit { args } {

    ns_parseargs { {-db ""} } $args

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set trans [ossweb::conn -incr $db:transaction -1]
    if { $trans == 0 } {
      if { [catch { ns_db dml $db "COMMIT TRANSACTION" } errmsg] } {
        ns_log Error "ossweb::db::commit: $errmsg"
      }
      ossweb::conn -set $db:transaction ""
    }
    return 0
}

# Rollbacks a database transaction.
proc ossweb::db::rollback { args } {

    ns_parseargs { {-db ""} } $args

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return
    }
    set trans [ossweb::conn $db:transaction]
    if { $trans > 0 } {
      if { [catch { ns_db dml $db "ROLLBACK TRANSACTION" } errmsg] } {
        ns_log Error "ossweb::db::rollback: $errmsg"
      }
    }
    ossweb::conn -set $db:transaction ""
}

# Returns number of rows affected by last INSERT,UPDATE or DELETE statement.
proc ossweb::db::rowcount { args } {

    ns_parseargs { {-db ""} } $args

    if { $db == "" && [set db [ossweb::db::handle]] == "" } {
      return 0
    }

    switch -glob [ns_db dbtype $db] {
      PostgreSQL {
        set count [ns_pg ntuples $db]
      }
      Sybase {
        set count [::ossweb::db::value $db "SELECT @@rowcount"]
      }
      default {
        error "Unsupported database driver: [ns_db dbtype $db]: [ns_db driver $db]"
      }
    }
    return $count
}

# Given error messages, parse it and display if applicable.
# Only specific OSS and/or DML messages will be displayed.
proc ossweb::db::parse_error { errmsg { sql "" } { id "" } } {

    if { [regexp {(OSSWEB:|OSS:)(.+)} $errmsg d p msg] } {
      regexp {(.+)CONTEXT:} $msg d msg
      ::ossweb::conn::set_msg -color red [string trim $msg { ""):}]
      return
    }
    if { [regexp {invalid input syntax for type (.+): "([^""]+)"} $errmsg d type data] } {
      ::ossweb::conn::set_msg -color red "Invalid $type data: $data"
      return
    }
    if { [regexp {Fail to add null value in not null attribute ([^ \r\n]+)} $errmsg d name] ||
         [regexp {null value in column "([^\"]+)" violates not-null constraint} $errmsg d name] } {
      ::ossweb::conn::set_msg -color red "Field '$name' cannot be empty"
      return
    }
    if { [regexp {violates foreign key constraint "[^"]+" on "([^"]+)"} $errmsg d name] ||
         [regexp {still referenced from ([^ \r\n]+)} $errmsg d name] } {
      ::ossweb::conn::set_msg -color red "Record is in use by $name"
      return
    }
    if { [regexp {Cannot insert a duplicate key|duplicate key value violates unique constraint} $errmsg] } {
      ::ossweb::conn::set_msg -color red "Record with the same value(s) already exists"
      return
    }
    # Add current callback name
    if { [set callback [ossweb::conn callback:name]] != "" } {
      append id " in $callback"
    }
    ossweb::conn::log Error ossweb::db::parse_error: $id: $errmsg: $sql
}

# Generates new unique id that can be used through-out the system(s),
# name is first part of sequence which should have full name as name_seq.
# By default ossweb_util_seq sequence is used for new ids or random number
# for non-sequence databases
proc ossweb::db::nextval { { name ossweb_util } } {

    set id [ossweb::db::value sql:ossweb.seq.nextval]
    if { $id == "" } {
      error "OSSWEB: Error in new ID generation"
    }
    return $id
}

# Returns last id used in the current transaction for specified sequence
proc ossweb::db::currval { { name ossweb_util } } {

     return [ossweb::db::value sql:ossweb.seq.currval]
}

# Save/restore local variable
proc ossweb::db::dbvars { cmd level { vars "" } { varray "" } } {

    global saved_db_vars

    # Append variables from given array
    if { $varray != "" } {
      upvar #$level $varray _vars
      ::foreach { _k _v } [array get _vars] {
        lappend vars $_k $_v
      }
    }

    switch -- $cmd {
     init {
       ::foreach { vk vv } $vars {
         upvar #$level $vk _var
         if { ![info exists _var] } {
           set _var $vv
         }
       }
     }

     set {
       ::foreach { vk vv } $vars {
         upvar #$level $vk _var
         set saved_db_vars($vk) [ossweb::coalesce _var]
         set _var $vv
       }
     }

     restore {
       ::foreach { vk vv } [array get saved_db_vars] {
          upvar #$level $vk _var
          set _var $vv
       }
       array unset saved_db_vars
     }
    }
}

# Parse parameters and split between WHERE condition from given list of columns
proc ossweb::sql::dbargs { params } {

    set where ""
    set dbargs [::list]

    ::foreach { k v } $params {
      if { [string index $k 0] == "-" } {
        if { $k == "-where" } {
          if { $v != "" } {
            if { $where != "" } {
              append where " AND "
            }
            append where $v
          }
        } else {
          lappend dbargs $k $v
        }
      } else {
        if { $k != "" && $v != "" } {
          if { $where != "" } {
            append where " AND "
          }
          if { [llength $v] > 1 && [string is double -strict [lindex $v 0]] } {
            append where "$k IN ([ossweb::sql::list $v])"
          } else {
            append where "$k=[ossweb::sql::quote $v string]"
          }
        }
      }
    }
    return [::list $dbargs $where]
}

# Returns 1 if given type is not valid SQL column type
proc ossweb::sql::ignore { type } {

    if { [lsearch -exact { hidden var inform } $type] >= 0 } {
      return 1
    }
    return 0
}

# Given table name, returns columns with converted type in format
# name type default ...
proc ossweb::sql::columns { table_name args } {

    ns_parseargs { {-flush f} } $args

    if { $flush == "t" } {
      ossweb::db::cache flush db:cols:$table_name
    }

    set columns [::list]
    foreach column [ossweb::db::multilist sql:ossweb.db.table.column.types -array t -cache db:cols:$table_name -timeout 3600] {
      set cname ""
      set ctype ""
      # Find name and type fields
      foreach { n v } $column {
        switch -- $n {
         name {
           set cname $v
         }
         type {
           set ctype $v
         }
        }
      }

      switch -regexp -nocase -- $ctype {
       bool { set ctype boolean }
       interval { set ctype "" }
       _int { set ctype "" }
       int { set ctype int }
       numeric - float - real { set ctype double }
       timestamp { set ctype datetime }
       time { set ctype time }
       date { set ctype date }
       default { set ctype "" }
      }
      lappend columns $cname $ctype ""
    }
    return $columns
}

# Create INSERT SQL statement from column definition array.
# Returns VALUE clause with all values filled.
#  -skip tells which columns should be omitted
#  -alias specifies prefix or table alias for the columns
#  -mask defines bit mask of all columns. If mask is non-empty and
#   any position doesn't contain 1, column with corresponding index will be ignored
#  -full t will genereate full SQL INSERT with columns
#  -nl is newline separator for more readable sql, empty by default
proc ossweb::sql::insert_values { args } {

    ns_parseargs { {-full f}
                   {-skip ""}
                   {-mask ""}
                   {-prefix ""}
                   {-array ""}
                   {-columns2 ""}
                   {-skip_null t}
                   {-keep ""}
                   {-level 1}
                   {-nl ""}
                   {-map ""} -- columns } $args
    set i -1
    set fields [::list]
    set values [::list]
    ::foreach { name value } $map {
      set cmap($name) $value
    }
    ::foreach { name type default } $columns2 {
      lappend columns $name $type $default
    }
    ::foreach { name type default } $columns {
      incr i
      if { [lsearch -exact $skip $name] >= 0 || [::ossweb::sql::ignore $type] } {
        continue
      }
      if { $mask != "" && [string index $mask $i] != "1" } {
        continue
      }
      set default [subst $default]
      if { $array != "" } {
        upvar $level ${array}($prefix$name) colname
      } else {
        upvar $level $prefix$name colname
      }
      # Perform column name mapping
      set name [ossweb::coalesce cmap($name) $name]
      # Type preprocessing
      switch -exact $type {
       skip_null {
         if { [set value [::ossweb::coalesce colname $default]] == "" } {
           continue
         }
       }
      }
      # Special handling for some types
      switch -exact $type {
       Const {
         set value $default
       }

       const {
         set value [ossweb::sql::quote $default]
       }

       userid {
         set value [ossweb::conn user_id $default]
       }

       timestamp {
         set value [::ossweb::coalesce colname $default]
         if { [string is integer -strict $value] && $value > 0 } {
           set value [ns_fmttime $value "'%Y-%m-%d %H:%M:%S'"]
         } else {
           set value [::ossweb::sql::quote $value $type]
         }
       }

       boolean {
         switch [ossweb::true [::ossweb::coalesce colname $default] 1] {
          0 { set value FALSE }
          1 { set value TRUE }
          "" { set value NULL }
         }
       }

       datetime -
       time -
       date {
         if { [info exists colname] } {
           if { [ossweb::date -check $colname] } {
             set value [::ossweb::sql::quote [::ossweb::date $type $colname] $type]
           } else {
             set value [::ossweb::sql::quote $colname $type]
           }
         } else {
           set value [::ossweb::sql::quote [::ossweb::date $type $default] $type]
         }
       }

       default {
         set value [::ossweb::sql::quote [::ossweb::coalesce colname $default] $type]
       }
      }
      # Skip nulls if t or e and varibale does not exists
      if { $value == "NULL" } {
        if { $skip_null == "t" || ($skip_null == "e" && ![info exists colname]) } {
          if { $keep == "" || ![ossweb::lexists $keep $name] } {
            continue
          }
        }
      }
      if { $full == "t" } {
        lappend fields $name
      }
      lappend values $value
    }
    # Generate columns part of insert statement
    if { $full == "t" } {
      return "([join $fields ","]) ${nl}VALUES([join $values ",${nl}"])"
    }
    return [join $values ","]
}

# Create UPDATE SQL statement from column definition array ( see ossweb::sql::quote, ossweb::conn::init_vars)
# Returns SET clause with all values filled.
#  -skip tells which columns should be omitted
#  -skip_null tells to ignore empty fields and do not include them into update list,
#   if -skip_null e, then include columns even if empty but present as variable
#  -keep defined list of columns that should always be present
#  -alias specifies prefix or table alias for the columns
#  -mask defines bit mask of all columns. If mask is non-empty and
# any position doesn't contain 1, column with corresponding index will be ignored
proc ossweb::sql::update_values { args } {

    ns_parseargs { {-mask ""}
                   {-map ""}
                   {-prefix ""}
                   {-array ""}
                   {-columns2 ""}
                   {-skip ""}
                   {-skip_null f}
                   {-keep ""}
                   {-level 1}
                   {-debug f} -- columns } $args
    set i -1
    set values ""
    ::foreach { name value } $map {
      set cmap($name) $value
    }
    ::foreach { name type default } $columns2 {
      lappend columns $name $type $default
    }
    ::foreach { name type default } $columns {
      incr i
      if { [lsearch -exact $skip $name] >= 0 || [::ossweb::sql::ignore $type] } {
        continue
      }
      if { $mask != "" && [string index $mask $i] != "1" } {
        continue
      }
      set default [subst $default]
      if { $array != "" } {
        upvar $level ${array}($prefix$name) colname
      } else {
        upvar $level $prefix$name colname
      }
      # Perform column name mapping
      set name [ossweb::coalesce cmap($name) $name]
      # Type preprocessing
      switch -exact $type {
       skip_null {
         if { [set value [::ossweb::coalesce colname $default]] == "" } {
           if { $keep == "" || ![ossweb::lexists $keep $name] } {
             continue
           }
         }
       }
      }
      # Special handling for some types
      switch -exact $type {
       Const {
         set value $default
       }

       const {
         set value [ossweb::sql::quote $default]
       }

       userid {
         set value [ossweb::conn user_id $default]
       }

       timestamp {
         set value [::ossweb::coalesce colname $default]
         if { [string is integer -strict $value] && $value > 0 } {
           set value [ns_fmttime $value "'%Y-%m-%d %H:%M:%S'"]
         } else {
           set value [::ossweb::sql::quote $value $type]
         }
       }

       boolean {
         switch [ossweb::true [::ossweb::coalesce colname $default] 1] {
          0 { set value FALSE }
          1 { set value TRUE }
          "" { set value NULL }
         }
       }

       datetime -
       time -
       date {
         if { [info exists colname] } {
           if { [ossweb::date -check $colname] } {
             set value [::ossweb::sql::quote [::ossweb::date $type $colname] $type]
           } else {
             set value [::ossweb::sql::quote $colname $type]
           }
         } else {
           set value [::ossweb::sql::quote [::ossweb::date $type $default] $type]
         }
       }

       default {
         set value [::ossweb::sql::quote [::ossweb::coalesce colname $default] $type]
       }
      }
      if { $debug == "t" } {
        ns_log Notice ossweb::sql::update_values: $name = $value
      }
      # Skip nulls if t or e and varibale does not exists
      if { $value == "NULL" } {
        if { $skip_null == "t" || ($skip_null == "e" && ![info exists colname]) } {
          if { $keep == "" || ![ossweb::lexists $keep $name] } {
            continue
          }
        }
      }
      if { $values != "" } { append values "," }
      append values $name "=" $value
    }
    return $values
}

# Builds filter SQL condition using column definition
#  -array specifies arry name where values should be taken instead of Tcl variables
#  -alias table alias for columns
#  -aliasmap defines alias for each column, it is list of
#                  alias prefixes in format:
#                     -aliasmap { c. {} b. }
#                  where first columns will have alias c., second one
#                  will have global -alias if defined or nothing, third
#                  column will have alias b.
#  -before SQL statement that should be put before condition
#  -after SQL statement that should be put after condition
#  -prefix is used for prefixing actual variables
#  -filter contains current SQL statement, it will be appended by new
#          filter conditions, if filter is provided -before will be applied to
#          it, i.e. if it is empty -before will not be used.
#  -where will be put at the beginning if -filter is not empty and
#         new filter is not empty too
#  -embed contains global SQL statement where new filter will be included
#         by substituting %sql%
#  -nullmap define how to treat empty columns, it is a list
#          whereby each item corresponds to column by position, if
#          it is set to 0 column will be checked IS NULL, if it is set to 1
#          then IS NOT NULL.
#          For ex. { name id } -nullmap { 0 1 }
#              resulting SQL will look like: name IS NULL AND id IS NOT NULL
#              if name and id is empty
#  -map defines columns which should be replaced with
#       custom pieces of SQL code instead of column name
#         For ex. set map { id "EXISTS(SELECT 1 FROM table WHERE id=%value)" }
#                 ossweb::sql::filer { id int ""} -map $map
#                 Without map, SQL statemnet would look like
#                    WHERE id=1
#                 but with the map it looks now
#                    WHERE EXISTS(SELECT 1 FROM table WHERE id=1)
#  -custom specifies any text with placeholders for column type 'custom'
#          '%name' will be replaced by column name,
#          '%value' will be replaced by column value
# Returns SQL condition
proc ossweb::sql::filter { columns args } {

    ns_parseargs { {-skip ""}
                   {-alias ""}
                   {-before ""}
                   {-after ""}
                   {-where ""}
                   {-filter NULL}
                   {-custom ""}
                   {-map ""}
                   {-embed ""}
                   {-array ""}
                   {-aliasmap ""}
                   {-level 1}
                   {-single f}
                   {-namemap ""}
                   {-opermap ""}
                   {-nullmap ""}
                   {-and AND}
                   {-prefix ""} } $args

    set i -1
    set sql ""

    # Column SQL mapping
    ::foreach { name value } $map {
      ossweb::db::xql value
      set cmap($name) [subst $value]
    }
    # Column name mapping
    ::foreach { name value } $namemap {
      set nmap($name) $value
    }
    # Operators maping
    ::foreach { name value } $opermap {
      set omap($name) $value
    }
    # Scan columns and prepare SQL statement
    ::foreach { name type default } $columns {
      incr i
      # NOT operator support
      set not ""
      if { [string index $type 0] == "!" } {
        set not NOT
        set type [string range $type 1 end]
      }
      if { [string range $type 0 2] == "not" } {
        set not NOT
        set type [string range $type 3 end]
      }
      # Ignore by name or by type
      if { [lsearch -exact $skip $name] >= 0 || [::ossweb::sql::ignore $type] } {
        continue
      }
      if { $array == "" } {
        upvar $level $prefix$name var
      } else {
        upvar $level ${array}($prefix$name) var
      }
      if { ![info exists var] || $var == "" } {
        # Do not create empty variables in the caller's frame
        if { [set value [subst $default]] == "" } {
          switch [lindex $nullmap $i] {
           0 { set type null }
           1 { set type notnull }
           default { continue }
          }
        }
        set var $value
      }
      if { $sql != "" } { append sql " $and " }
      # Special values
      switch -- $var {
       null - NULL {
         set type null
       }
       '' {
         set var ""
       }
      }
      # Set table alias
      set nprefix [ossweb::nvl [lindex $aliasmap $i] $alias]
      set name [ossweb::coalesce nmap($name) $name]
      switch -- $type {
       null {
          append sql "$nprefix$name IS $not NULL"
       }

       userid {
         append sql "$nprefix$name = [ossweb::conn user_id $default]"
       }

       between {
          append sql "$nprefix$name $not BETWEEN [::ossweb::sql::quote [lindex $var 0]] AND [::ossweb::sql::quote [lindex $var 1]]"
       }

       list -
       ilist {
          set value [::ossweb::sql::list $var $type]
          if [info exists cmap($name)] {
            regsub -all {%value} $cmap($name) $value data
            append sql $data
          } else {
            append sql "$nprefix$name $not IN ($value)"
          }
       }

       time -
       date -
       datetime {
          if [info exists cmap($name)] {
            set value [ossweb::date $type $var]
            regsub -all {%value} $cmap($name) $value data
            append sql $data
          } else {
            append sql "$nprefix$name $not [::ossweb::date range $var]"
          }
       }

       daterange {
          if [info exists cmap($name)] {
            set value [ossweb::date range $var -date]
            regsub -all {%value2} $cmap($name) [lindex $value 1] data
            regsub -all {%value} $data [lindex $value 0] data
            append sql $data
          } else {
            append sql "$nprefix$name $not [::ossweb::date range $var]"
          }
       }

       regexp -
       Regexp {
          set oper ~
          if { $not != "" } { set not ! }
          if { [string index $type 0] == "R" } { set oper ~* }
          if [info exists cmap($name)] {
            regsub -all {%value} $cmap($name) [::ossweb::sql::quote $var] data
            append sql $data
          } else {
            append sql "$nprefix$name $not$oper [::ossweb::sql::quote $var]"
          }
       }

       custom {
          set data $custom
          ossweb::db::xql data
          regsub -all {%name} $data $name data
          regsub -all "'" $var "''" var
          regsub -all {\\} $var {\\\\} var
          regsub -all {%value} $data $var data
          append sql $data
       }

       default {
          # Special case of case-insensitive search
          switch -- $type {
           str - text - Text { set oper ILIKE }
           like - Like { set oper LIKE }
           tsearch { set oper @@ }
           default { set oper [ossweb::coalesce omap($name) =] }
          }
          if [info exists cmap($name)] {
            regsub -all {%value} $cmap($name) [::ossweb::sql::quote $var $type] data
            append sql $data
          } else {
            append sql "$nprefix$name $not $oper [::ossweb::sql::quote $var $type]"
          }
       }
      }
      # Stop after first non empty column
      if { $single == "t" } { break }
    }
    # Embed filter into bigger SQL statemenmt
    if { $embed != "" && $sql != "" } {
      ossweb::db::xql embed
      regsub -all {%sql} $embed $sql sql
    }

    if { $sql != "" } {
      if { $filter == "NULL" } {
        return "$where $before $sql $after"
      }
      if { $filter == "" && $where != "" } {
        set before ""
      }
      return "$where $filter $before $sql $after"
    }
    if { $filter != "NULL" } {
      if { $where != "" && $filter != "" } {
        return "$where $filter"
      }
      return $filter
    }
    return
}

# Convert a TCL list to a SQL list, performs quoting
proc ossweb::sql::list { lst { type "" }} {

    set sql [::list]
    ::foreach item $lst {
      lappend sql [ossweb::sql::quote $item $type]
    }
    return [join $sql ","]
}

# Perform quoting of the value according to SQL rules, empty value will be returned as NULL.
proc ossweb::sql::quote { value { type "" } } {

    set types { decimal double integer int int4 real smallint bigint bit float numeric tinyint ilist Const }
    switch -- $type {
     string {
     }

     boolean {
       if { $value == "" } {
         return NULL
       }
       switch -- $value {
        0 - f - N - No { return FALSE }
        1 - t - Y - Yes { return TRUE }
        default { return $value }
       }
     }

     default {
       if { $value == "" } {
         return NULL
       }
       if { [string toupper $value] == "NULL" } {
         return Null
       }
       if { [lsearch -exact $types $type] != -1 } {
         return $value
       }
       # Subtypes of string
       switch -- $type {
        like -
        text {
          set value $value%
        }

        Like -
        Text {
          set value %$value%
        }

        tsearch {
          return "to_tsquery('[join [split [string map { ' '' } $value]] { \& }]')"
        }
       }
     }
    }
    set value [string map { ' '' \\ \\\\ } $value]
    return "'$value'"
}

# Create multipage array, may be used with <multipage> tag to display
# multipage header/footer.
# ids is a total list of records(IDs), the proc returns id range according to
# given page number.
proc ossweb::sql::multipage { id args } {

    ns_parseargs { {-level {[expr [info level]-1]}}
                   {-ids ""}
                   {-flush f}
                   {-return ""}
                   {-user_id {[ossweb::conn user_id]}}
                   {-page 1}
                   {-cmd cmd}
                   {-cmd_name page}
                   {-pagesize 30}
                   {-query ""}
                   {-url ""}
                   {-cache ""}
                   {-timeout 600} } $args

    if { $flush == "t" } {
      ossweb::db::cache flush mp:$id:$user_id:*
      if { $cache != "" } {
        ossweb::cache flush $cache:*
      }
      return
    }
    # Backward compatibility
    if { ![string match *:mp $id] } {
      append id :mp
    }
    upvar #$level $id pages
    # Return the array
    switch -- $return {
     "" {
     }
     rowcount -
     pagecount -
     next_page -
     previous_page -
     page_rowcount -
     start -
     end {
       return [ossweb::coalesce pages($return)]
     }
     t {
       return [array get pages]
     }
     default {
       return
     }
    }
    set pages(cmd) $cmd
    set pages(url) $url
    set pages(query) $query
    set pages(timeout) $timeout
    set pages(cmd_name) $cmd_name
    set pages(rowcount) [llength $ids]
    set pages(pagecount) [expr ($pages(rowcount)-1-(($pages(rowcount)-1)%$pagesize))/$pagesize+1]
    set pages(next_page) {}
    set pages(previous_page) {}
    if { $page <= 0 || ![string is integer -strict $page] } { set page 1 }
    if { $page > 1 } { set pages(previous_page) [expr $page - 1] }
    if { $page < $pages(pagecount) } { set pages(next_page) [expr $page + 1] }
    set pages(start) [expr ($page-1)*$pagesize]
    set pages(end) [expr $pages(start)+$pagesize-1]
    if { $pages(end) >= [llength $ids] } { set pages(end) [expr [llength $ids]-1] }
    set ids [lrange $ids $pages(start) $pages(end)]
    set pages(page_rowcount) [llength $ids]
    incr pages(start)
    incr pages(end)
    return $ids
}

