import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/config/model/teams/team_member.dart'; 
import 'all_avatar.dart';
import 'alphabet_avatar.dart';
import 'profile_avatar.dart';

class ProfileAvatarRow extends StatelessWidget {
  final ScrollController scrollController;

  const ProfileAvatarRow({Key? key, required this.scrollController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      final teamMembers = controller.teamMembers;
      final selectedLetters = controller.selectedLetters;

      // Sort team members
      List<TeamMember> sortedTeamMembers = List.from(teamMembers);
      sortedTeamMembers.sort(
        (a, b) =>
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
      );

      // Get unique letters
      Set<String> uniqueLetters = {};
      for (var member in sortedTeamMembers) {
        if (member.firstLetter.isNotEmpty) {
          uniqueLetters.add(member.firstLetter);
        }
      }

      List<String> sortedLetters = uniqueLetters.toList()..sort();

      return SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 90,
          padding: const EdgeInsets.only(top: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Always show All button first
              AllAvatar(),

              // Build letters with their members inline
              ...sortedLetters.expand(
                (letter) => _buildLetterWithMembers(
                  letter,
                  sortedTeamMembers,
                  selectedLetters,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildLetterWithMembers(
    String letter,
    List<TeamMember> teamMembers,
    Set<String> selectedLetters,
  ) {
    List<Widget> widgets = [];
    bool isSelected = selectedLetters.contains(letter);

    // Add the letter avatar
    widgets.add(AlphabetAvatar(letter: letter));

    // If letter is selected, add its members right after
    if (isSelected) {
      List<TeamMember> letterMembers = teamMembers.where((member) {
        return member.firstLetter == letter;
      }).toList();

      // Sort members alphabetically
      letterMembers.sort(
        (a, b) =>
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
      );

      // Add member avatars
      for (int i = 0; i < letterMembers.length; i++) {
        widgets.add(ProfileAvatar(member: letterMembers[i], index: i + 1));
      }
    }

    return widgets;
  }
}
