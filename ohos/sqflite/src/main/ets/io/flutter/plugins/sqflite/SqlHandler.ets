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

import { Operation } from './operation/Operation';
import { relationalStore } from '@kit.ArkData';
import { Tools } from './Tools';
import { BusinessError } from '@kit.BasicServicesKit';
import { Constant } from './OhosConstant';

/// 每个 Handler 都要实现 match + execute
export interface ISqlHandler {
  // 如果能处理此 SQL，就返回 true
  match(sql: string): boolean;
  // 执行逻辑，返回是否执行成功
  execute( sql: string, operation: Operation, db: relationalStore.RdbStore): Promise<boolean> | boolean;
  // 默认 false，表示不走后处理；某些 Handler 可以覆盖为 true
  get needsPostProcess(): boolean;
}

/// 抽象 Handler，提供默认 no-op 实现
abstract class BaseSqlHandler implements ISqlHandler {
  match(sql: string): boolean {
    return false;
  }

  execute(sql: string, operation: Operation, db: relationalStore.RdbStore): Promise<boolean> | boolean {
    return false;
  }

  get needsPostProcess(): boolean {
    return false;
  }
}

/// 事务开始
export class BeginImmediateHandler extends BaseSqlHandler {
  match(sql: string) {
    return sql.toUpperCase() === Constant.SQL_BEGIN_IMMEDIATE;
  }

  execute(_sql: string, operation: Operation, db: relationalStore.RdbStore) {
    db.beginTransaction();
    return true;
  }

  get needsPostProcess(): boolean {
    return true;
  }
}

/// 提交事务
export class CommitHandler extends BaseSqlHandler {
  match(sql: string) {
    return sql.toUpperCase() === Constant.SQL_COMMIT;
  }

  execute(sql: string, operation: Operation, db: relationalStore.RdbStore) {
    db.commit();
    return true;
  }

  get needsPostProcess(): boolean {
    return true;
  }
}

/// BEGIN EXCLUSIVE
export class BeginExclusiveHandler extends BaseSqlHandler {
  match(sql: string) {
    return sql.toUpperCase() === Constant.SQL_BEGIN_EXCLUSIVE;
  }
  execute(_sql: string, operation: Operation, _db: relationalStore.RdbStore) {
    return true;
  }
  get needsPostProcess(): boolean {
    return true;
  }
}

/// ATTACH
export class AttachHandler extends BaseSqlHandler {
  match(sql: string) {
    return Tools.startsWithIgnoreCase(sql, Constant.SQL_ATTACH);
  }
  execute(sql: string, operation: Operation, db: relationalStore.RdbStore) {
    return this.handleAttach(db, sql, operation);
  }

  private async handleAttach(db: relationalStore.RdbStore, sql: string, operation: Operation): Promise<boolean> {
    const sqlArguments: string[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS);

    const exprPattern = /attach\s+(?:database\s+)?([^\s;]+?)(?:\s+as\s+)/i;
    const exprMatch = sql.match(exprPattern);
    let fullPath: string = '';
    if (exprMatch) {
      fullPath = ((exprMatch[1].trim() == '?') ? sqlArguments![0] : exprMatch[1].trim());
    }

    const schemaPattern = /\s+as\s+([^\s;]+)/i;
    const schemaMatch = sql.match(schemaPattern);
    let attachName: string = '';
    if (schemaMatch) {
      attachName = ((schemaMatch[1].trim() == '?') ? (sqlArguments![sqlArguments!.length - 1]) : schemaMatch[1].trim());
    }

    try {
      await db.attach(fullPath, attachName);
      operation.success(null);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      operation.error(Constant.SQLITE_ERROR, `attach failed, error code: ${error.code}. message is ${error.message}`, '');
      return false;
    }
  }
}

/// DETACH
export class DetachHandler extends BaseSqlHandler {
  match(sql: string) {
    return Tools.startsWithIgnoreCase(sql, Constant.SQL_DETACH);
  }
  execute(sql: string, operation: Operation, db: relationalStore.RdbStore) {
    return this.handleDetach(db, sql, operation);
  }

  private async handleDetach(db: relationalStore.RdbStore, sql: string, operation: Operation): Promise<boolean> {
    const sqlArguments: string[] | undefined = operation.getArgument(Constant.PARAM_SQL_ARGUMENTS);

    const schemaPattern = /detach\s+(?:database\s+)?([^\s;]+)/i;
    const schemaMatch = sql.match(schemaPattern);
    let attachName: string = '';
    if (schemaMatch) {
      attachName = ((schemaMatch[1].trim() == '?') ? (sqlArguments![0]) : schemaMatch[1].trim());
    }

    try {
      await db.detach(attachName);
      operation.success(null);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      operation.error(Constant.SQLITE_ERROR, `detach failed, error code: ${error.code}. message is ${error.message}`, '');
      return false;
    }
  }
}