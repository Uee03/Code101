export const safeReturn = (value: string) => value.startsWith('/') && !value.startsWith('//') && !value.includes('\\') ? value : '/';
