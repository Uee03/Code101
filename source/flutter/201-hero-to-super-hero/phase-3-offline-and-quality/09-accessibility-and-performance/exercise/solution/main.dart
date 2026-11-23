// Exercise 09: is this text readable? Run with: dart run main.dart
import 'dart:math';

/// A colour as red, green and blue, each from 0 to 255.
class Rgb {
  const Rgb(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;
}

/// WCAG 2.x: one channel from the stored sRGB value to linear light.
double linear(int channel) {
  final c = channel / 255;
  if (c <= 0.04045) {
    return c / 12.92;
  }
  return pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double luminance(Rgb colour) {
  return 0.2126 * linear(colour.red) +
      0.7152 * linear(colour.green) +
      0.0722 * linear(colour.blue);
}

double contrast(Rgb first, Rgb second) {
  final a = luminance(first);
  final b = luminance(second);
  final lighter = max(a, b);
  final darker = min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Text needs a ratio of at least 4.5 : 1 (WCAG 2.x level AA, normal size).
bool textIsReadable(Rgb text, Rgb background) {
  return contrast(text, background) >= 4.5;
}

/// A touch target should be at least 48 x 48 dp.
bool targetIsBigEnough(double widthDp, double heightDp) {
  return widthDp >= 48 && heightDp >= 48;
}

void report(String label, Rgb text, Rgb background) {
  final ratio = contrast(text, background).toStringAsFixed(2);
  final verdict = textIsReadable(text, background) ? 'pass' : 'fail';
  print('$label: $ratio $verdict');
}

void main() {
  const white = Rgb(255, 255, 255);
  report('black on white', const Rgb(0, 0, 0), white);
  report('grey 767676 on white', const Rgb(0x76, 0x76, 0x76), white);
  report('grey 777777 on white', const Rgb(0x77, 0x77, 0x77), white);
  report('white on white', white, white);
  print('target 48 x 48: ${targetIsBigEnough(48, 48) ? 'ok' : 'too small'}');
  print('target 40 x 48: ${targetIsBigEnough(40, 48) ? 'ok' : 'too small'}');
}
