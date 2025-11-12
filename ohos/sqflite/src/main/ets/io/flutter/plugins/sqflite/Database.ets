/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
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

import common from '@ohos.app.ability.common';
import relationalStore from '@ohos.data.relationalStore';
import { Operation } from './operation/Operation';
import { SqlCommand } from './SqlCommand';
import { ValueType } from '@ohos.data.ValuesBucket';
import { Constant } from './OhosConstant';
import { BusinessError } from '@ohos.base';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { MethodCallOperation } from './operation/MethodCallOperation';
import { BatchOperation } from './operation/BatchOperation';
import { Any } from '@ohos/flutter_ohos';
import {
  AttachHandler,
  BeginExclusiveHandler,
  BeginImmediateHandler,
  CommitHandler,
  DetachHandler,
  ISqlHandler
} from './SqlHandler';
import { deviceInfo } from '@kit.BasicServicesKit';


type HandleCallback = (x: Object) => void;

export class Database {
  public context: common.Context;
  public path: string;
  public id: number;
  public singleInstance: boolean;
  public logLevel: number;
  private static lastTransactionId: number = 0;
  private static currentTransactionId: number | null;
  private static transactionDepth: number = 0;

  constructor(context: common.Context, path: string, id: number, singleInstance: boolean, logLevel: number) {
    this.context = context;
    this.path = path;
    this.id = id;
    this.singleInstance = singleInstance;
    this.logLevel = logLevel;
  }

  private static handlers: ISqlHandler[] = [
    new BeginImmediateHandler(),
    new CommitHandler(),
    new BeginExclusiveHandler(),
    new AttachHandler(),
    new DetachHandler(),
  ];

  private static enterOrLeaveInTransaction(value: Boolean): void {
    if (value == true) {
      Database.transactionDepth++;
    } else if (value == false) {
      Database.transactionDepth--;
    }
  }

  private static handleException(operation: Operation, err: BusinessError<void>) {
    let code = err.code;
    let message = err.message;
    if (code == Constant.RDB_ERROR_CODE_801) {
      message = message + " Database is readonly"
    }
    operation.error(Constant.SQLITE_ERROR, 'error code:' + code + '。' + message, '');
  }

  private static async executeOrError(operation: Operation, db: relationalStore.RdbStore,
    callback?: HandleCallback): Promise<boolean> {
    let command: SqlCommand = operation.getSqlCommand();
    let operationInTransaction: boolean = operation.getInTransactionChange();
    let sqlArguments: ValueType[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS);
    let sql: string = command.getSql();
    let promise: ValueType;
    try {
      if (sqlArguments == undefined || sqlArguments.length < 1) {
        promise = await db.execute(sql) as ValueType;
      } else {
        promise = await db.execute(sql, sqlArguments) as ValueType;
      }

      Database.enterOrLeaveInTransaction(operationInTransaction);
      if (callback != undefined) {
        callback(promise)
      }
      return true;
    } catch (err) {
      Database.handleException(operation, err);
      return false;
    }
  }

  /// execute
  public static async execute(operation: Operation, db: relationalStore.RdbStore): Promise<void> {
    const sql = operation.getSqlCommand().getSql();
    const inTransactionChange = operation.getInTransactionChange();
    const enteringTransaction = inTransactionChange && operation.hasNullTransactionId();

    if (enteringTransaction) {
      Database.currentTransactionId = ++(Database.lastTransactionId);
      ;
    }

    const handler = Database.handlers.find((h) => h.match(sql));
    let success: boolean;
    if (handler) {
      const result = handler.execute(sql, operation, db);
      success = result instanceof Promise ? await result : result;
    } else {
      success = await Database.executeOrError(operation, db);
    }
    if (handler?.needsPostProcess ?? true) {
      Database.enterOrLeaveInTransaction(inTransactionChange);
      Database.handleExecute(success, enteringTransaction, operation, inTransactionChange);
    }
  }

  private static handleExecute(executeSuccess: boolean, enteringTransaction: boolean, operation: Operation,
    inTransactionChange: boolean) {
    if (!executeSuccess) {
      // Revert if needed
      if (enteringTransaction) {
        Database.currentTransactionId = null;
      }
    } else if (enteringTransaction) {
      /// Return the transaction id;
      if (Database.currentTransactionId != null) {
        let res: Map<String, Object> = new Map();
        res.set(Constant.PARAM_TRANSACTION_ID, Database.currentTransactionId);
        operation.success(res);
      } else {
        operation.success(null);
      }
    } else {
      if (inTransactionChange == false) {
        Database.currentTransactionId = null;
      }
      operation.success(null);
    }
  }

  public static async doExecute(operation: Operation, db: relationalStore.RdbStore): Promise<boolean> {
    let executeSuccess: boolean = await Database.executeOrError(operation, db);
    if (!executeSuccess) {
      return false;
    }
    operation.success(null);
    return true;
  }

  /// insert
  public static insert(operation: Operation, db: relationalStore.RdbStore): void {
    Database.doInsert(operation, db);
  }

  private static async doInsert(operation: Operation, db: relationalStore.RdbStore): Promise<boolean> {
    let executeSuccess: boolean = await Database.executeOrError(operation, db, (rowId) => {
      operation.success(rowId);
    });
    if (!executeSuccess) {
      return false;
    }

    // don't get last id if not expected
    if (operation.getNoResult()) {
      operation.success(null);
      return true;
    }
    return true;
  }

  /// update
  public static update(operation: Operation, db: relationalStore.RdbStore): void {
    Database.doUpdate(operation, db);
  }

  private static async doUpdate(operation: Operation, db: relationalStore.RdbStore): Promise<boolean> {
    let executeSuccess: boolean = await Database.executeOrError(operation, db, (rows) => {
      operation.success(rows);
    });
    if (!executeSuccess) {
      return false;
    }

    // don't get last id if not expected
    if (operation.getNoResult()) {
      operation.success(null);
      return true;
    }
    return true;
  }

  /// query
  public static query(operation: Operation, db: relationalStore.RdbStore): void {
    Database.doQuery(operation, db);
  }

  private static async doQuery(operation: Operation, db: relationalStore.RdbStore): Promise<boolean> {

    let command: SqlCommand = operation.getSqlCommand();
    let sql: string = command.getSql();

    if (sql == Constant.SQL_PRAGMA_USER_VERSION) {
      let versionMap: Map<String, object> = new Map<String, object>();
      versionMap.set(Constant.PARAM_COLUMNS, [Constant.PARAM_USER_VERSION]);
      versionMap.set(Constant.PARAM_ROWS, [[db.version]]);
      operation.success(versionMap);
      return true;
    }

    let cursorPageSize: number | undefined = operation.getArgument(Constant.PARAM_CURSOR_PAGE_SIZE);
    let sqlArguments: ValueType[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS);
    let suc: boolean = false;

    if (sqlArguments != undefined && sqlArguments.length > 0) {
      try {
        let resultSet = await db.querySql(sql, sqlArguments);
        suc = Database.handleQuerySqlResult(operation, resultSet, cursorPageSize);
        return suc;
      } catch (err) {
        Database.handleException(operation, err);
        return false;
      }
    } else {
      try {
        let resultSet = await db.querySql(sql);
        suc = Database.handleQuerySqlResult(operation, resultSet, cursorPageSize);
        return suc;
      } catch (err) {
        Database.handleException(operation, err);
        return false;
      }
    }
  }

  private static handleQuerySqlResult(operation: Operation, resultSet: relationalStore.ResultSet,
    cursorPageSize: number | undefined): boolean {

    let results: Map<String, object> = new Map<String, Object>();
    let rows: Array<Array<Object>> = new Array<Array<Object>>();
    let columns: Array<string> | null = null;
    let valuesType: Array<string> | null = null;
    let columnCount: number = 0;

    // resultSet是一个数据集合得游标，默认值想第-1个记录，有效的数据从0开始
    while (resultSet.goToNextRow()) {
      if (columns == null) {
        columnCount = resultSet.columnCount;
        columns = new Array<string>();
        rows = new Array<Array<Object>>();
        valuesType = new Array<string>();
        let row: Record<string, ValueType> = resultSet.getRow() as Record<string, ValueType>;
        for (let i = 0; i < columnCount; i++) {
          let columnName = resultSet.getColumnName(i);
          columns.push(columnName);
          let valueType: string = typeof row[columnName];
          valuesType.push(valueType);
        }
        results.set(Constant.PARAM_COLUMNS, columns);
        results.set(Constant.PARAM_ROWS, rows);
      }

      let row = Database.cursorRowToList(resultSet, columnCount, valuesType);
      rows.push(row);
      if (cursorPageSize != null) {
        if (rows.length >= cursorPageSize) {
          break;
        }
      }
    }

    operation.success(results);
    // 释放数据集的内存
    resultSet.close();
    return true;
  }

  static cursorRowToList(cursor: relationalStore.ResultSet, length: number,
    valuesType: Array<string> | null): Array<Object> {
    let list = new Array<Object>();

    for (let i = 0; i < length; i++) {
      let value: Object = Database.cursorValue(cursor, i, valuesType![i]);
      list.push(value);
    }
    return list;
  }

  static cursorValue(cursor: relationalStore.ResultSet, index: number, valueType: Any | null): Any {
    if ('number' == valueType) {
      let value = cursor.getString(index);
      let isIntegerString = /^-?\d+$/.test(value);
      if (value && isIntegerString) {
        let valueBig = BigInt(value);
        if (valueBig > Number.MAX_SAFE_INTEGER || valueBig < Number.MIN_SAFE_INTEGER) {
          return valueBig;
        } else {
          return Number.parseInt(valueBig.toString());
        }
      }
    }
    return cursor.getValue(index);
  }

  /// batch
  public static async batch(call: MethodCall, result: MethodResult, db: relationalStore.RdbStore): Promise<void> {

    let mainOperation: MethodCallOperation = new MethodCallOperation(call, result);
    let noResult: boolean = mainOperation.getNoResult();
    let continueOnError: boolean = mainOperation.getContinueOnError();

    let operations: Array<Map<string, Object>> =
      mainOperation.getArgument(Constant.PARAM_OPERATIONS) as Array<Map<string, Object>>;
    let results: Array<Map<string, Object>> = new Array();

    for (let index = 0; index < operations.length; index++) {

      const map: Map<string, Object> = operations[index];
      let operation: BatchOperation = new BatchOperation(map, noResult);
      const method: string = operation.getMethod();

      let executeSuc: boolean;
      switch (method) {
        case Constant.METHOD_EXECUTE:
          executeSuc = await Database.doExecute(operation, db);
          if (executeSuc) {
            operation.handleSuccess(results);
          } else if (continueOnError) {
            operation.handleErrorContinue(results);
          } else {
            return;
          }
          break;
        case Constant.METHOD_INSERT:
          executeSuc = await Database.doInsert(operation, db);
          if (executeSuc) {
            operation.handleSuccess(results);
          } else if (continueOnError) {
            operation.handleErrorContinue(results);
          } else {
            operation.handleError(result);
            return;
          }
          break;
        case Constant.METHOD_QUERY:
          executeSuc = await Database.doQuery(operation, db);
          if (executeSuc) {
            operation.handleSuccess(results);
          } else if (continueOnError) {
            operation.handleErrorContinue(results);
          } else {
            operation.handleError(result);
            return;
          }
          break;
        case Constant.METHOD_UPDATE:
          executeSuc = await Database.doUpdate(operation, db);
          if (executeSuc) {
            operation.handleSuccess(results);
          } else if (continueOnError) {
            operation.handleErrorContinue(results);
          } else {
            operation.handleError(result);
            return;
          }
          break;
        default:
          result.error(Constant.ERROR_BAD_PARAM, "Batch method " + method + "not supported", null);
          return;
      }
    }
    if (noResult) {
      result.success(null);
    } else {
      result.success(results);
    }
  }
}