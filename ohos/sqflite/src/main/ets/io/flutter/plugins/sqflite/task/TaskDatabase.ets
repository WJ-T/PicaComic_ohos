/*
* Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import taskPool from '@ohos.taskpool';
import common from '@ohos.app.ability.common';
import { logger } from '../../utils/Logger';
import { Operation } from '../operation/Operation';
import { SqlCommand } from '../SqlCommand';
import { Constant } from '../OhosConstant';
import relationalStore from '@ohos.data.relationalStore';
import { ValueType } from '@ohos.data.ValuesBucket';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { DatabaseHelper } from '../DatabaseHelper';

const TAG = 'TaskDatabase';


@Concurrent
async function query(context: common.Context, config: relationalStore.StoreConfig,
  sql: string, sqlArguments: ValueType[], cursorPageSize: number): Promise<Map<String, Object>> {

  const db = await relationalStore.getRdbStore(context, config);

  const results: Map<String, Object> = new Map<String, Object>();

  let resultSet = await db.querySql(sql, sqlArguments);

  let rows: Array<Array<Object>> = new Array<Array<Object>>();
  let columns: Array<string> | null = null;
  let valuesType: Array<string> | null = null;
  let columnCount: number = 0;

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

    let row = new Array<Object>();

    for (let index = 0; index < columnCount; index++) {
      let rowValue: Object | null = null;
      const valuesTypeItem = valuesType![index];
      if ('number' == valuesTypeItem) {
        let value = resultSet.getString(index);
        let isIntegerString = /^-?\d+$/.test(value);
        if (value && isIntegerString) {
          let valueBig = BigInt(value);
          if (valueBig > Number.MAX_SAFE_INTEGER || valueBig < Number.MIN_SAFE_INTEGER) {
            rowValue = valueBig;
          } else {
            rowValue = Number.parseInt(valueBig.toString());
          }
        }
        else{
          rowValue = resultSet.getValue(index);
        }
      } else {
        rowValue = resultSet.getValue(index);
      }
      row.push(rowValue!!);
    }
    rows.push(row);
    if (cursorPageSize != null && cursorPageSize != -1) {
      if (rows.length >= cursorPageSize) {
        break;
      }
    }
  }

  // 释放数据集的内存
  resultSet.close();
  db.close();
  return results;
}


@Concurrent
async function insert(context: common.Context, config: relationalStore.StoreConfig,
  sql: string, sqlArguments: ValueType[]): Promise<ValueType | undefined> {
  const db = await relationalStore.getRdbStore(context, config);
  const res: ValueType | undefined = await db.execute(sql,sqlArguments) as ValueType;
  db.close();
  return res;
}

export async function taskPoolExecuteQuery(context: common.Context, operation: Operation,db: relationalStore.RdbStore): Promise<void> {
  try {
    const command: SqlCommand = operation.getSqlCommand();
    const sql: string = command.getSql();
    const sqlArguments: ValueType[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS) as ValueType[];
    const cursorPageSize: number | undefined = operation.getArgument(Constant.PARAM_CURSOR_PAGE_SIZE) as number;
    const config = getStoreConfig(operation);

    // 查询版本的不使用 taskPool 线程
    if (sql == Constant.SQL_PRAGMA_USER_VERSION) {
      const result: Map<String, Object> = new Map<String, Object>();
      result.set(Constant.PARAM_COLUMNS, [Constant.PARAM_USER_VERSION]);
      result.set(Constant.PARAM_ROWS, [[db.version]]);
      operation.success(result);
    }
    else{
      const task: taskPool.Task =
        new taskPool.Task(query, context,config, sql, sqlArguments ?? [], cursorPageSize ?? -1);
      const result: Map<String, Object> = await taskPool.execute(task) as Map<String, Object>;
      operation.success(result);
    }
  } catch (err) {
    handleException(operation, err);
  }
}

export async function taskPoolExecuteInsert(context: common.Context, operation: Operation): Promise<void> {
  try {
    const command: SqlCommand = operation.getSqlCommand();
    const sql: string = command.getSql();
    const sqlArguments: ValueType[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS) as ValueType[];
    const config = getStoreConfig(operation);

    const task: taskPool.Task = new taskPool.Task(insert, context, config, sql, sqlArguments ?? []);
    const result: ValueType | undefined = await taskPool.execute(task) as ValueType;
    if(result){
      operation.success(result);
    }
    else{
      operation.success(null);
    }
  } catch (err) {
    handleException(operation, err);
  }
}

function getStoreConfig(operation: Operation):relationalStore.StoreConfig{

  const currentDbId: number | undefined = operation.getArgument(Constant.PARAM_ID) as number;
  const dbName: string = DatabaseHelper.getMemoryDatabaseNameByDatabaseId(currentDbId);
  const isReadOnly: boolean = DatabaseHelper.dbIdOnlyMap.get(currentDbId) ?? false;

  const config: relationalStore.StoreConfig = {
    name: dbName, // 数据库文件名
    securityLevel: relationalStore.SecurityLevel.S1,
    isReadOnly: isReadOnly,
    tokenizer: undefined
  }

  if(deviceInfo.sdkApiVersion >= Constant.API_17){
    config.tokenizer = relationalStore.Tokenizer.ICU_TOKENIZER
  }

  return config;
}

function handleException(operation: Operation, err: BusinessError<void>) {
  let code = err.code;
  let message = err.message;
  if (code == Constant.RDB_ERROR_CODE_801) {
    message = message + " Database is readonly"
  }
  logger.error(TAG, 'error code:' + code + '。' + message);
  operation.error(Constant.SQLITE_ERROR, 'error code:' + code + '。' + message, '');
}