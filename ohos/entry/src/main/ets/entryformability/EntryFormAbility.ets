import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import type Want from '@ohos.app.ability.Want';
import type common from '@ohos.app.ability.common';
import type { Configuration } from '@kit.AbilityKit';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import {
  createHistoryWidgetBinding,
  readFormRecords,
  readHistorySnapshot,
  readHistorySnapshotSync,
  removeFormRecord,
  saveFormRecord,
  updateAllHistoryForms,
  updateHistoryForm,
} from '../plugins/widget/WidgetBridge';

const TAG: string = 'EntryFormAbility';
const DOMAIN: number = 0xD00510A;

function readStringParameter(want: Want, key: string): string {
  const parameters = want.parameters as Record<string, Object> | undefined;
  const rawValue = parameters?.[key];
  if (typeof rawValue === 'string') {
    return rawValue;
  }
  if (typeof rawValue === 'number') {
    return rawValue.toString();
  }
  if (rawValue instanceof String) {
    return rawValue.toString();
  }
  if (rawValue instanceof Number) {
    return rawValue.valueOf().toString();
  }
  return '';
}

function readNumberParameter(want: Want, key: string): number {
  const parameters = want.parameters as Record<string, Object> | undefined;
  const rawValue = parameters?.[key];
  if (typeof rawValue === 'number') {
    return rawValue;
  }
  if (rawValue instanceof Number) {
    return rawValue.valueOf();
  }
  return formInfo.FormDimension.Dimension_2_2;
}

function readMessageString(message: string, key: string): string {
  try {
    const parsed = JSON.parse(message) as Record<string, Object>;
    const rawValue = parsed[key];
    if (typeof rawValue === 'string') {
      return rawValue;
    }
    if (rawValue instanceof String) {
      return rawValue.toString();
    }
  } catch (_) {
  }
  return '';
}

function dimensionFromCardMode(cardMode: string): number {
  if (cardMode === '2') {
    return formInfo.FormDimension.Dimension_4_4;
  }
  if (cardMode === '1') {
    return formInfo.FormDimension.Dimension_2_4;
  }
  return formInfo.FormDimension.Dimension_2_2;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onConfigurationUpdate(newConfig: Configuration): void {
    const context = this.context as common.Context;
    hilog.error(DOMAIN, TAG, `onConfigurationUpdate colorMode=${newConfig.colorMode}`);
    updateAllHistoryForms(
      context,
      undefined,
      newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
    ).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `update forms for configuration failed: ${error.message}`);
    });
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = readStringParameter(want, formInfo.FormParam.IDENTITY_KEY);
    const dimension = readNumberParameter(want, formInfo.FormParam.DIMENSION_KEY);
    const context = this.context as common.Context;
    hilog.error(DOMAIN, TAG, `onAddForm formId=${formId} dimension=${dimension}`);
    saveFormRecord(context, formId, dimension).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `saveFormRecord failed: ${error.message}`);
    });
    this.refreshForm(context, formId, dimension);
    return createHistoryWidgetBinding(context, readHistorySnapshotSync(context), dimension);
  }

  async onUpdateForm(formId: string): Promise<void> {
    const context = this.context as common.Context;
    const records = await readFormRecords(context);
    const record = records.find((item) => item.formId === formId);
    const dimension = record?.dimension ?? formInfo.FormDimension.Dimension_2_2;
    const snapshot = await readHistorySnapshot(context);
    try {
      await updateHistoryForm(context, formId, snapshot, dimension);
      hilog.error(DOMAIN, TAG, `onUpdateForm updated formId=${formId} dimension=${dimension}`);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `onUpdateForm failed: ${message}`);
    }
  }

  onRemoveForm(formId: string): void {
    const context = this.context as common.Context;
    removeFormRecord(context, formId).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `removeFormRecord failed: ${error.message}`);
    });
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    const context = this.context as common.Context;
    hilog.error(DOMAIN, TAG, `onChangeFormVisibility ids=${Object.keys(newStatus).join(',')}`);
    updateAllHistoryForms(context).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `update visible forms failed: ${error.message}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    const context = this.context as common.Context;
    const eventName = readMessageString(message, 'pica_widget_message');
    if (eventName !== 'refresh_history') {
      hilog.error(DOMAIN, TAG, `ignore form event formId=${formId} message=${message}`);
      return;
    }
    this.refreshFormFromEvent(context, formId, readMessageString(message, 'pica_widget_card_mode'))
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `refreshFormFromEvent failed: ${error.message}`);
      });
  }

  private async refreshFormFromEvent(
    context: common.Context,
    formId: string,
    cardMode: string,
  ): Promise<void> {
    hilog.error(DOMAIN, TAG, `onFormEvent refresh formId=${formId} mode=${cardMode}`);
    await updateAllHistoryForms(context);
  }

  private async refreshForm(
    context: common.Context,
    formId: string,
    dimension: number,
  ): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    try {
      const snapshot = await readHistorySnapshot(context);
      await updateHistoryForm(context, formId, snapshot, dimension);
      hilog.error(DOMAIN, TAG, `refreshForm updated formId=${formId} dimension=${dimension}`);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `refreshForm failed: ${message}`);
    }
  }
}
