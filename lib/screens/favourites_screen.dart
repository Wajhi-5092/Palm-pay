import 'package:flutter/material.dart';
import '../widgets/favourites/favourite_item.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final List<String> categories = [
    'All',
    'Easyload',
    'Bill Payment',
    'User Contacts',
  ];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color.fromARGB(255, 0, 147, 200);
    const Color bgColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Favourites',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCategoryFilters(primaryGreen),
          _buildSearchBar(),
          Expanded(child: _buildFavouritesGrid()),
        ],
      ),
      floatingActionButton: _buildAddButton(primaryGreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCategoryFilters(Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: categories.map((cat) {
          bool isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedCategory = cat);
              },
              selectedColor: color,
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? color : Colors.grey.shade200,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search favourites by name',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: Icon(
              Icons.search,
              color: Colors.grey,
              size: 28,
            ), // Image shows it on the right
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFavouritesGrid() {
    // Mock data matching the image items
    final favourites = [
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
      {
        'name': 'Dummy User',
        'initials': 'DU',
        'icon': Icons.home,
        'type': 'home',
      },
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemCount: favourites.length,
      itemBuilder: (context, index) {
        final fav = favourites[index];
        return FavouriteItem(
          name: fav['name'] as String,
          initials: fav['initials'] as String?,
          imageUrl: fav['image'] as String?,
          typeIcon: fav['icon'] as IconData?,
        );
      },
    );
  }

  Widget _buildAddButton(Color color) {
    return Container(
      width: 240,
      height: 56,
      margin: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: color,
        elevation: 10,
        label: const Text(
          '+ Add Favorites',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
