import 'package:school_desk_app/bloc/bottom_bar_bloc/bottom_bar_bloc.dart';
import 'package:school_desk_app/school.dart';
import 'package:school_desk_app/view/authorised/category/category_screen.dart';
import 'package:school_desk_app/view/authorised/home/home_screen.dart';
import 'package:school_desk_app/view/widget/home_bottom_nav_bar.dart';

class BottomBarScreen extends StatelessWidget {
  const BottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomBarBloc(),
      child: const _BottomBarScaffold(),
    );
  }
}

class _BottomBarScaffold extends StatelessWidget {
  const _BottomBarScaffold();

  static const _items = <HomeBottomNavBarItem>[
    HomeBottomNavBarItem(label: 'Home', icon: Icons.home_rounded),
    HomeBottomNavBarItem(label: 'Categories', icon: Icons.grid_view_rounded),
    HomeBottomNavBarItem(
      label: 'Explore',
      icon: Icons.auto_awesome_rounded,
      isCenter: true,
    ),
    HomeBottomNavBarItem(label: 'Offers', icon: Icons.local_offer_rounded),
    HomeBottomNavBarItem(label: 'Orders', icon: Icons.receipt_long_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const CategoryScreen(),
      const _PlaceholderScreen(title: 'Explore'),
      const _PlaceholderScreen(title: 'Offers'),
      const _PlaceholderScreen(title: 'Orders'),
    ];

    return BlocBuilder<BottomBarBloc, BottomBarState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: IndexedStack(index: state.currentIndex, children: pages),
          bottomNavigationBar: HomeBottomNavBar(
            items: _items,
            currentIndex: state.currentIndex,
            onTap: (index) {
              context.read<BottomBarBloc>().add(BottomBarTabChanged(index));
            },
          ),
        );
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          title,
          style: context.h1.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
