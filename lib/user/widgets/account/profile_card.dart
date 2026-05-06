import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 0, 62, 104);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 350;

        return Container(
          padding: EdgeInsets.all(isSmall ? 14 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 55 : 70,
                height: isSmall ? 55 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.tealAccent, width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://ui-avatars.com/api/?name=AA&background=003E68&color=fff&size=150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 FIX: prevent overflow in top row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Account Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 15 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildEditButton(cardColor, isSmall),
                      ],
                    ),

                    SizedBox(height: isSmall ? 2 : 4),

                    Text(
                      'Phone Number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 11 : 13,
                      ),
                    ),

                    Text(
                      'Email Address',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmall ? 10 : 11,
                      ),
                    ),

                    SizedBox(height: isSmall ? 6 : 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'IBAN: PK07TMFB000000000001',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmall ? 9 : 10,
                            ),
                            overflow: TextOverflow.clip,
                          ),
                        ),
                        Icon(
                          Icons.copy_outlined,
                          color: Colors.white,
                          size: isSmall ? 14 : 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditButton(Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            size: isSmall ? 10 : 12,
            color: color,
          ),
          SizedBox(width: isSmall ? 2 : 4),
          Text(
            'Edit',
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
