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

import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { Constant } from '../OhosConstant';
import { BaseOperation } from './BaseOperation';
import { OperationResult } from './OperationResult';

export class BatchOperation extends BaseOperation {
  private operationResult: BatchOperationResult = new BatchOperationResult();
  public map: Map<string, Object>;
  public noResult: boolean;

  constructor(map: Map<string, Object>, noResult: boolean) {
    super();
    this.map = map;
    this.noResult = noResult;
  }

  getMethod(): string {
    return this.map.get(Constant.PARAM_METHOD) as string;
  }

  getArgument<T>(key: string): T {
    return this.map.get(key) as T;
  }

  hasArgument(key: string): boolean {
    return this.map.has(key);
  }

  getOperationResult(): OperationResult {
    return this.operationResult;
  }

  public getOperationSuccessResult(): Map<string, Object | null> {
    let results: Map<string, Object | null> = new Map<string, Object | null>();
    results.set(Constant.PARAM_RESULT, this.operationResult.result);
    return results;
  }

  public getOperationError(): Map<string, Object> {
    let error: Map<string, Object> = new Map<string, Object>();
    let errorDetail: Map<string, Object> = new Map<string, Object>();
    errorDetail.set(Constant.PARAM_ERROR_CODE, this.operationResult.errorCode);
    errorDetail.set(Constant.PARAM_ERROR_MESSAGE, this.operationResult.errorMessage);
    errorDetail.set(Constant.PARAM_ERROR_DATA, this.operationResult.errorData);
    error.set(Constant.PARAM_ERROR_DATA, errorDetail);
    return error;
  }

  public handleError(result: MethodResult): void {
    result.error(this.operationResult.errorCode, this.operationResult.errorMessage, this.operationResult.errorData);
  }

  getNoResult(): boolean {
    return this.noResult;
  }

  public handleSuccess(results: Array<Map<string, Object | null>>): void {
    if(!this.getNoResult()) {
      results.push(this.getOperationSuccessResult());
    }
  }

  public handleErrorContinue(results: Array<Map<string, Object>>): void {
    if(!this.getNoResult()) {
      results.push(this.getOperationError());
    }
  }
}

export class BatchOperationResult implements OperationResult {
  // success
  result: Object | null = null;
  // error
  errorCode: string = '';
  errorMessage: string = '';
  errorData: Object = '';

  error(errorCode: string, errorMessage: string, data: Object): void {
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.errorData = data;
  }

  success(result: Object): void {
    this.result = result;
  }
}

export class OperationError {
  public errorCode: string;
  public errorMessage: string;
  public errorData: Object;

  constructor(errorCode: string, errorMessage: string, data: Object) {
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.errorData = data;
  }
}