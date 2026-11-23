export const apiEvents = new EventTarget();
let notice = { message: '', until: 0 };
export function notify(message: string, seconds = 0) {
  notice = { message, until: seconds ? Date.now() + seconds * 1000 : 0 };
  apiEvents.dispatchEvent(new Event('notice'));
}
export const getNotice = () => notice;
