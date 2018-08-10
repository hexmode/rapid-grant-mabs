<?php
error_reporting( -1 );
ini_set( 'display_errors', 1 );
ini_set( 'display_startup_errors', 1 );
$wgShowSQLErrors = true;
$wgDebugDumpSql  = true;
$wgShowDBErrorBacktrace = true;
$wgShowExceptionDetails = true;
$wgDebugLogFile = "$IP/cache/debug.log";
