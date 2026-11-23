import { AbstractControl } from '@angular/forms';

export interface Issue {
  field: string;
  label: string;
  text: string;
}

// One short sentence for the first problem of a control, or null when it has none.
// A server message (from a 422 answer) wins because it is the most specific.
export function issueText(control: AbstractControl): string | null {
  if (control.hasError('server')) {
    return String(control.getError('server'));
  }
  if (control.hasError('required')) {
    return $localize`:@@issue.required:Enter a title.`;
  }
  if (control.hasError('maxlength')) {
    return $localize`:@@issue.tooLong:The text is too long.`;
  }
  if (control.hasError('angleBrackets')) {
    return $localize`:@@issue.brackets:Remove the characters < and >.`;
  }
  if (control.hasError('titleTaken')) {
    return $localize`:@@issue.taken:This title is already used.`;
  }
  if (control.hasError('pastDate')) {
    return $localize`:@@issue.past:Choose today or a later date.`;
  }
  return null;
}
