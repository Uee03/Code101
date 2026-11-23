export type ValidityFlag = Exclude<keyof ValidityState, "valid">;
type Rule = readonly [flag: ValidityFlag, message: string];

const RULES: Readonly<Record<string, readonly Rule[]>> = {
  title: [
    ["valueMissing", "Enter a title."],
    ["tooShort", "The title must be at least 3 characters."],
    ["customError", "Enter at least 3 characters that are not spaces."],
  ],
  due: [
    ["valueMissing", "Choose a due date."],
    ["badInput", "Enter a valid date."],
    ["rangeUnderflow", "The due date cannot be in the past."],
  ],
  priority: [["valueMissing", "Choose a priority."]],
};

export function messageFor(name: string, validity: ValidityState): string | null {
  if (validity.valid) {
    return null;
  }
  for (const [flag, message] of RULES[name] ?? []) {
    if (validity[flag]) {
      return message;
    }
  }
  return "Check this field.";
}

export function summaryTitle(_count: number): string {
  return "There is a problem";
}
