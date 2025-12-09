import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    if (category == 'All tasks') return Icons.assignment;
    final lower = category.trim().toLowerCase();

    // Standard Categories
    if (lower.contains('work') ||
        lower.contains('job') ||
        lower.contains('office')) return Icons.work_outline;
    if (lower.contains('personal') || lower.contains('life'))
      return Icons.person_outline;
    if (lower.contains('shopping') ||
        lower.contains('buy') ||
        lower.contains('grocer')) return Icons.shopping_bag_outlined;
    if (lower.contains('health') ||
        lower.contains('doctor') ||
        lower.contains('med')) return Icons.favorite_border;
    if (lower.contains('learning') ||
        lower.contains('school') ||
        lower.contains('study') ||
        lower.contains('book')) return Icons.school_outlined;

    // Smart Mappings - Extended
    if (lower.contains('travel') ||
        lower.contains('trip') ||
        lower.contains('flight') ||
        lower.contains('plane')) return Icons.flight_takeoff;
    if (lower.contains('gym') ||
        lower.contains('fitness') ||
        lower.contains('sport') ||
        lower.contains('workout') ||
        lower.contains('exercise')) return Icons.fitness_center;
    if (lower.contains('food') ||
        lower.contains('diet') ||
        lower.contains('meal') ||
        lower.contains('cook') ||
        lower.contains('restaurant')) return Icons.restaurant;
    if (lower.contains('money') ||
        lower.contains('finance') ||
        lower.contains('bill') ||
        lower.contains('bank') ||
        lower.contains('budget') ||
        lower.contains('invest')) return Icons.attach_money;
    if (lower.contains('home') ||
        lower.contains('house') ||
        lower.contains('rent')) return Icons.home_outlined;
    if (lower.contains('car') ||
        lower.contains('auto') ||
        lower.contains('drive')) return Icons.directions_car_outlined;
    if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('film')) return Icons.movie_outlined;
    if (lower.contains('code') ||
        lower.contains('dev') ||
        lower.contains('tech') ||
        lower.contains('soft') ||
        lower.contains('app') ||
        lower.contains('web')) return Icons.computer;
    if (lower.contains('game') || lower.contains('gaming'))
      return Icons.sports_esports;
    if (lower.contains('music') || lower.contains('song'))
      return Icons.music_note;
    if (lower.contains('art') || lower.contains('design')) return Icons.brush;
    if (lower.contains('party') ||
        lower.contains('birthday') ||
        lower.contains('event')) return Icons.cake;
    if (lower.contains('pet') ||
        lower.contains('dog') ||
        lower.contains('cat') ||
        lower.contains('vet')) return Icons.pets;
    if (lower.contains('exam') ||
        lower.contains('test') ||
        lower.contains('class') ||
        lower.contains('course')) return Icons.school_outlined;

    return Icons.category_outlined;
  }

  static Color getColor(String category) {
    if (category == 'All tasks') return Colors.white;
    final lower = category.trim().toLowerCase();

    if (lower.contains('work')) return Colors.orange;
    if (lower.contains('personal')) return Colors.blue;
    if (lower.contains('shopping')) return Colors.green;
    if (lower.contains('health')) return Colors.red;
    if (lower.contains('learning')) return Colors.purple;

    // Smart Colors
    if (lower.contains('travel') || lower.contains('trip'))
      return Colors.lightBlue;
    if (lower.contains('gym') || lower.contains('fitness'))
      return Colors.blueGrey;
    if (lower.contains('food') || lower.contains('diet'))
      return Colors.orangeAccent;
    if (lower.contains('money') || lower.contains('finance'))
      return Colors.green.shade700;
    if (lower.contains('home') || lower.contains('house')) return Colors.brown;
    if (lower.contains('car') || lower.contains('auto')) return Colors.indigo;
    if (lower.contains('movie')) return Colors.redAccent;
    if (lower.contains('code') || lower.contains('tech'))
      return const Color(0xFF2D3142);
    if (lower.contains('game')) return Colors.deepPurpleAccent;
    if (lower.contains('music')) return Colors.pinkAccent;
    if (lower.contains('art')) return Colors.teal;
    if (lower.contains('party')) return Colors.pink;
    if (lower.contains('pet')) return Colors.brown.shade300;
    if (lower.contains('exam') || lower.contains('class'))
      return Colors.amber.shade800;

    return Colors.grey;
  }
}
