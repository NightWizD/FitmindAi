import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(BuildContext, int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.secondaryCard,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            bool isSelected = index == currentIndex;
            return GestureDetector(
              onTap: () => onTap(context, index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  [Icons.dashboard, Icons.fitness_center_rounded, Icons.restaurant_menu_rounded, Icons.person_rounded][index],
                  color: isSelected ? Colors.white : AppColors.textDim,
                  size: 28,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
