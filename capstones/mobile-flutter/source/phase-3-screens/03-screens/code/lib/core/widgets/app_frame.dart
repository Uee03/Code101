import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/strings.dart';
import 'art_icon.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({super.key,required this.title,required this.child,this.actions,this.floatingActionButton});
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions,automaticallyImplyLeading:false,
      leading:context.canPop() ? IconButton(tooltip:Strings.text('back'),
        onPressed:() => context.pop(),icon:ArtIcon('log-out',Strings.text('back'))) : null),
    body: SafeArea(child: child), floatingActionButton: floatingActionButton,
    bottomNavigationBar: NavigationBar(selectedIndex: GoRouterState.of(context).uri.path.startsWith('/settings') ? 1 : 0,
      onDestinationSelected: (index) => context.go(index == 0 ? '/teams' : '/settings'),
      destinations: [
        NavigationDestination(icon: ArtIcon('team',Strings.text('teams')),label: Strings.text('teams')),
        NavigationDestination(icon: ArtIcon('settings',Strings.text('settings')),label: Strings.text('settings')),
      ]),
  );
}
