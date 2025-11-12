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

import { SqlCommand } from '../SqlCommand';
import { OperationResult } from './OperationResult';

export interface Operation extends OperationResult {
  getMethod(): string;

  getArgument<T>(key: string): T;

  hasArgument(key: string): boolean;

  getSqlCommand(): SqlCommand;

  getNoResult(): boolean;

  // In batch, means ignoring the error
  getContinueOnError(): boolean;

  // Only for execute command, true when entering a transaction, false when exiting
  getInTransactionChange(): boolean;

  /**
   * transaction id if any, only for within a transaction
   */
   getTransactionId(): number | null;

  /**
   * Transaction v2 support
   */
  hasNullTransactionId(): boolean;
}