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

import ArrayList from '@ohos.util.ArrayList';
import { ValueType } from '@ohos.data.ValuesBucket';

export class SqlCommand {
  sql: string;
  rawArguments: Array<ValueType>;

  constructor(sql: string, rawArguments: Array<ValueType> | undefined) {
    this.sql = sql;
    if(rawArguments == undefined) {
      rawArguments = new Array;
    }
    this.rawArguments = rawArguments;
  }

  // Handle list of int as byte[]
  static toValue(value: ValueType): ValueType {
    return value;
  }

  public getSql(): string {
    return this.sql;
  }

  public getRawSqlArguments(): Array<Object> {
    return this.rawArguments;
  }
}