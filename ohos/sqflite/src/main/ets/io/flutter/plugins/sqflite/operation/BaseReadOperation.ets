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

import { Constant } from '../OhosConstant';
import { SqlCommand } from '../SqlCommand';
import { Operation } from './Operation';
import { OperationResult } from './OperationResult';
import { ValueType } from '@ohos.data.ValuesBucket';

export abstract class BaseReadOperation implements Operation {
  private getSql(): string {
    return this.getArgument(Constant.PARAM_SQL);
  }

  private getSqlArguments(): Array<ValueType> {
    return this.getArgument(Constant.PARAM_SQL_ARGUMENTS);
  }

  public getTransactionId(): number | null {
    return this.getArgument(Constant.PARAM_TRANSACTION_ID);
  }

  public hasNullTransactionId(): boolean {
    return this.hasArgument(Constant.PARAM_TRANSACTION_ID) && this.getTransactionId() == null;
  }

  public getSqlCommand(): SqlCommand {
    return new SqlCommand(this.getSql(), this.getSqlArguments());
  }

  public getInTransactionChange(): boolean {
    return this.getBoolean(Constant.PARAM_IN_TRANSACTION_CHANGE);
  }

  getNoResult(): boolean {
    if(this.getArgument<object>(Constant.PARAM_NO_RESULT)) {
      return true;
    }
    return false;
  }

  getContinueOnError(): boolean {
    if(this.getArgument<object>(Constant.PARAM_CONTINUE_OR_ERROR)) {
      return true;
    }
    return false;
  }

  private getBoolean(key: string): boolean {
    let value: object = this.getArgument(key);
    if(typeof value == 'boolean') {
      return value;
    }
    return false;
  }

  protected abstract getOperationResult(): OperationResult;

  public toString(): string {
    return "" + this.getMethod() + "" + this.getSql() + "" + this.getSqlArguments();
  }

  getMethod(): string {
    throw new Error('Method not implemented.');
  }

  getArgument<T>(key: string): T {
    throw new Error('Method not implemented.');
  }

  hasArgument(key: string): boolean {
    throw new Error('Method not implemented.');
  }

  error(errorCode: string, errorMessage: String, data: object): void {
    throw new Error('Method not implemented.');
  }

  success(result: object): void {
    throw new Error('Method not implemented.');
  }
}