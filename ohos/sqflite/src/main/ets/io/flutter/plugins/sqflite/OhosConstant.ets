/*
 * Copyright (c) 2021-2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export class Constant {
  // Can be used as the name MethodChannel or to register with
  static PLUGIN_KEY: string = "com.tekartik.sqflite";
  static METHOD_GET_PLATFORM_VERSION: string = "getPlatformVersion";
  static METHOD_GET_DATABASES_PATH: string = "getDatabasesPath";
  static METHOD_DEBUG: string = "debug";
  static METHOD_OPTIONS: string = "options";
  static METHOD_OPEN_DATABASE: string = "openDatabase";
  static METHOD_CLOSE_DATABASE: string = "closeDatabase";
  static METHOD_INSERT: string = "insert";
  static METHOD_EXECUTE: string = "execute";
  static METHOD_QUERY: string = "query";
  static METHOD_QUERY_CURSOR_NEXT: string = "queryCursorNext";
  static METHOD_UPDATE: string = "update";
  static METHOD_BATCH: string = "batch";
  static METHOD_DELETE_DATABASE: string = "deleteDatabase";
  static METHOD_DATABASE_EXISTS: string = "databaseExists";
  // true when entering, false when leaving, null otherwise, should be named inTransactionChange instead
  static PARAM_IN_TRANSACTION_CHANGE: string = "inTransaction";
  // Set for calls within a transaction
  static PARAM_TRANSACTION_ID: string = "transactionId";
  // Special transaction id used for recovering a locked database.
  public TRANSACTION_ID_FORCE: number = -1;
  // Result when opening a database
  public PARAM_RECOVERED: string = "recovered";
  // Result when opening a database
  public PARAM_RECOVERED_IN_TRANSACTION: string = "recoveredInTransaction";
  static PARAM_SQL: string = "sql";
  static PARAM_SQL_ARGUMENTS: string = "arguments";
  static PARAM_NO_RESULT: string = "noResult";
  static PARAM_CONTINUE_OR_ERROR: string = "continueOnError";
  static PARAM_COLUMNS: string = "columns";
  static PARAM_ROWS: string = "rows";
  // For query to use a cursor.Integer.
  static PARAM_CURSOR_PAGE_SIZE: string = "cursorPageSize";
  // For queryCursorNext. Integer
  static PARAM_CURSOR_ID: string = "cursorId";
  // For queryCursorNext. Integer
  public PARAM_CANCEL: string = "cancel";
  // in each operation
  static PARAM_METHOD: string = "method";
  // Batch operation results
  public static PARAM_RESULT: string = "result";
  public static PARAM_ERROR: string = "error";
  // map with code/message/data
  public static PARAM_ERROR_CODE: string = "code";
  public static PARAM_ERROR_MESSAGE: string = "message";
  public static PARAM_ERROR_DATA: string = "data";
  // android log tag
  static TAG: string = "Sqflite";
  // Obsolete since 1.17
  static METHOD_DEBUG_MODE: string = "debugMode";
  static METHOD_ANDROID_SET_LOCALE: string = "androidSetLocale";
  // Locale tag
  static PARAM_LOCALE: string = "locale";
  // public static final String[]
  // static EMPTY_STRING_ARRAY = new String[0];
  static PARAM_ID: string = "id";
  static PARAM_PATH: string = "path";
  // when opening a database
  static PARAM_READ_ONLY: string = "readOnly"; // boolean
  static PARAM_SINGLE_INSTANCE: string = "singleInstance"; // boolean
  static PARAM_LOG_LEVEL: string = "logLevel"; // int
  static PARAM_THREAD_PRIORITY: string = "androidThreadPriority"; // int
  static PARAM_THREAD_COUNT: string = "androidThreadCount"; // int
  static PARAM_USER_VERSION = "user_version";
  //debugMode
  static PARAM_CMD: string = "cmd"; // debugMode cmd:get/set
  static CMD_GET: string = "get";
  // in batch
  static PARAM_OPERATIONS: string = "operations";
  static SQLITE_ERROR: string = "sqlite_error"; // code
  static ERROR_BAD_PARAM: string = "bad_param"; // internal only
  static ERROR_OPEN_FAILED: string = "open_failed"; // msg
  static ERROR_DATABASE_CLOSED: string = "database_closed"; // msg
  // memory database path
  static MEMORY_DATABASE_PATH: string = ":memory:";
  static SQL_BEGIN_IMMEDIATE: string = "BEGIN IMMEDIATE";
  static SQL_COMMIT: string = "COMMIT";
  static SQL_BEGIN_EXCLUSIVE: string = "BEGIN EXCLUSIVE";
  static SQL_ATTACH: string = "ATTACH";
  static SQL_DETACH: string = "DETACH";
  static SQL_PRAGMA_USER_VERSION = "PRAGMA user_version";
  static API_17 = 17;
  static API_20 = 20;
  static DB_PATH_PARSING_BEGIN_INDEX = 6;
  static RDB_ERROR_CODE_801 = 801;
}