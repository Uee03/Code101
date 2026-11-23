import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ArtIcon extends StatelessWidget {
  const ArtIcon(this.name, this.label, {super.key});
  final String name;
  final String label;
  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/icons/$name.svg',
    width: 24, height: 24, semanticsLabel: label,
    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface,BlendMode.srcIn));
}
