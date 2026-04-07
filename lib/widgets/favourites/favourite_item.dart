import 'package:flutter/material.dart';

class FavouriteItem extends StatelessWidget {
  final String name;
  final String? initials;
  final String? imageUrl;
  final IconData? typeIcon;

  const FavouriteItem({
    super.key,
    required this.name,
    this.initials,
    this.imageUrl,
    this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color.fromARGB(255, 0, 140, 200);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 1. Circle Avatar Area
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 1.5),
                color: Colors.white,
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          initials ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
              ),
            ),
            // 2. Three Dots Menu Button
            Positioned(
              top: 0,
              right: -5,
              child: IconButton(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: Colors.black54),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 3. Name Label
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // 4. Type Icon (Small Logo/Home/Zong)
        if (typeIcon != null)
          Icon(
            typeIcon,
            size: 14,
            color: primaryGreen,
          ),
      ],
    );
  }
}
