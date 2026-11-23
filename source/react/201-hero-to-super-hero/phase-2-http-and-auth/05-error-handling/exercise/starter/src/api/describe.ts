import { ApiProblem } from './problem';

export type ErrorView = {
  heading: string;
  message: string;
  retryable: boolean;
  details: string[];
};

export function describeError(error: unknown): ErrorView {
  if (error instanceof ApiProblem) {
    switch (error.status) {
      case 401:
        return { heading: 'Please sign in', message: 'Your session is missing or has expired.', retryable: false, details: [] };
      case 403:
        return { heading: 'You do not have access', message: 'Ask a team lead if you need it.', retryable: false, details: [] };
      case 404:
        return {
          heading: 'Not found',
          message: 'This item does not exist, or you may not see it.',
          retryable: false,
          details: [],
        };
      case 409:
        // TODO: when error.code is 'last_lead', use the heading 'This team needs a lead'
        // and the message 'Assign another lead before you remove or demote this one.'
        return {
          heading: 'Conflict',
          message: error.detail ?? 'The change conflicts with the current data.',
          retryable: false,
          details: [],
        };
      case 412:
        return {
          heading: 'Someone changed this first',
          message: 'Reload the item and apply your change again.',
          retryable: false,
          details: [],
        };
      case 422:
        return {
          heading: 'Please check the form',
          message: error.detail ?? 'Some values are not valid.',
          retryable: false,
          details: (error.errors ?? []).map((item) => `${item.pointer}: ${item.detail}`),
        };
      case 429:
        return {
          heading: 'Too many requests',
          message: error.retryAfter ? `Wait ${error.retryAfter} seconds, then try again.` : 'Wait a moment, then try again.',
          retryable: true,
          details: [],
        };
      default:
        if (error.status >= 500) {
          return {
            heading: 'The server had a problem',
            message: 'This is not your fault. Try again in a moment.',
            retryable: true,
            details: [],
          };
        }
        return { heading: 'The request failed', message: error.detail ?? error.title, retryable: false, details: [] };
    }
  }
  if (error instanceof TypeError) {
    return {
      heading: 'You may be offline',
      message: 'The request did not reach the server. Check your connection.',
      retryable: true,
      details: [],
    };
  }
  return { heading: 'Something went wrong', message: 'An unexpected error happened.', retryable: false, details: [] };
}
