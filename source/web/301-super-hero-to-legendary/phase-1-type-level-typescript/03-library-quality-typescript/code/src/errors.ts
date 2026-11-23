export class ParseError extends Error {
  override readonly name: string = 'ParseError';
  // A short preview, never the whole input: inputs can be large or contain secrets.
  readonly inputPreview: string;

  constructor(message: string, inputPreview: string, options?: ErrorOptions) {
    super(message, options);
    this.inputPreview = inputPreview;
  }
}
