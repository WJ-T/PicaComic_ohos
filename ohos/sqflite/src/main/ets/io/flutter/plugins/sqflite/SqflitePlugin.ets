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
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { DatabaseHelper } from './DatabaseHelper';
import { Constant } from './OhosConstant';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { Database } from './Database';
import { MethodCallOperation } from './operation/MethodCallOperation';
import { taskPoolExecuteQuery,taskPoolExecuteInsert } from './task/TaskDatabase';

export default class SqflitePlugin implements FlutterPlugin, MethodCallHandler {
  private context: common.Context | null = null;
  private channel: MethodChannel | null = null;


  getUniqueClassName(): string {
    return "SqflitePlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), Constant.PLUGIN_KEY);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case Constant.METHOD_OPEN_DATABASE:
        this.handleOpenDatabaseCall(call, result);
        break;
      case Constant.METHOD_GET_DATABASES_PATH:
        this.handleGetDatabasesPathCall(call, result);
        break;
      case Constant.METHOD_DATABASE_EXISTS:
        this.handleDatabaseExistsCall(call, result);
        break;
      case Constant.METHOD_EXECUTE:
        this.handleExecuteCall(call, result);
        break;
      case Constant.METHOD_INSERT:
        this.handleInsertCall(call, result);
        break;
      case Constant.METHOD_QUERY:
        this.handleQueryCall(call, result);
        break;
      case Constant.METHOD_UPDATE:
        this.handleUpdateCall(call, result);
        break;
      case Constant.METHOD_BATCH:
        this.handleBatchCall(call, result);
        break;
      case Constant.METHOD_OPTIONS:
        this.handleOptionsCall(call, result);
        break;
      case Constant.METHOD_DEBUG_MODE:
        this.handleDebugModeCall(call, result);
        break;
      case Constant.METHOD_GET_PLATFORM_VERSION:
        this.handleGetPlatformVersionCall(call, result);
        break;
      case Constant.METHOD_CLOSE_DATABASE:
        this.handleCloseDatabaseCall(call, result);
        break;
      case Constant.METHOD_DELETE_DATABASE:
        this.handleDeleteDatabaseCall(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  ///打开数据库
  async handleOpenDatabaseCall(call: MethodCall, result: MethodResult): Promise<void> {
    await DatabaseHelper.openDatabase(this.context!, call, result);
  }

  ///获取数据库路径
  handleGetDatabasesPathCall(call: MethodCall, result: MethodResult) {
    let appContext = this.context!.getApplicationContext();
    let path: string = appContext.databaseDir + "/rdb";
    result.success(path);
  }

  ///检查数据库是否存在
  async handleDatabaseExistsCall(call: MethodCall, result: MethodResult): Promise<void> {
    let dbPath: string = call.argument(Constant.PARAM_PATH);
    let isExist: boolean = await DatabaseHelper.checkDatabaseExisted(dbPath);
    result.success(isExist);
  }

  ///执行Sql
  async handleExecuteCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }
    let operation: MethodCallOperation = new MethodCallOperation(call, result);

    Database.execute(operation, rdbStore);
  }

  ///插入数据
  async handleInsertCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }

    let operation: MethodCallOperation = new MethodCallOperation(call, result);
    Database.insert(operation, rdbStore);
  }

  ///查询数据
  async handleQueryCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }
    const operation: MethodCallOperation = new MethodCallOperation(call, result);
    taskPoolExecuteQuery(this.context!,operation,rdbStore);
  }

  ///更新（包括删除）数据
  async handleUpdateCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }


    let operation: MethodCallOperation = new MethodCallOperation(call, result);
    Database.update(operation, rdbStore);
  }

  ///batch操作
  async handleBatchCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }
    Database.batch(call, result, rdbStore);
  }

  ///Options操作，设置LogLevel，仅限开发，已废弃
  async handleOptionsCall(call: MethodCall, result: MethodResult): Promise<void> {
    DatabaseHelper.options(call, result);
  }

  ///设置debug模式，已废弃
  async handleDebugModeCall(call: MethodCall, result: MethodResult): Promise<void> {
    DatabaseHelper.debugMode(call, result);
  }

  ///获取设备信息
  async handleGetPlatformVersionCall(call: MethodCall, result: MethodResult): Promise<void> {
    DatabaseHelper.getPlatformVersion(call, result);
  }

  ///关闭数据库
  async handleCloseDatabaseCall(call: MethodCall, result: MethodResult): Promise<void> {
    let rdbStore = DatabaseHelper.getDatabaseOrError(call, result);
    if (rdbStore == null) {
      return;
    }
    await DatabaseHelper.closeDatabase(call, result);
  }

  ///删除数据库
  async handleDeleteDatabaseCall(call: MethodCall, result: MethodResult): Promise<void> {
    let dataBaseName: string = call.argument(Constant.PARAM_PATH);
    let res = await DatabaseHelper.deleteDatabase(this.context!, dataBaseName);
    if (res) {
      result.success(null);
    }else {
      result.error('-1', 'Delete database failed', '');
    }
  }
}